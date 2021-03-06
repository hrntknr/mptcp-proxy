#include <string.h>
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ipv6.h>
#include <netinet/ip6.h>
#include <linux/tcp.h>
#include <arpa/inet.h>

#include "bpf_helpers.h"
#include "bpf_endian.h"
#include "jhash.h"

#define SERVICE_MAP_SIZE 64
#define BACKEND_ARRAY_SIZE 64
#define SUBFLOW_CACHE_SIZE 4096

#define MAX_TCPOPT_LEN 16
#define PERF_SIZE 1

#define TCPOPT_NOP 1
#define TCPOPT_EOL 0
#define TCPOPT_MPTCP 30

#define MPTCP_SUB_CAPABLE 0
#define MPTCP_SUB_JOIN 1

#define MPTCP_SUB_LEN_CAPABLE_SYN 12
#define MPTCP_SUB_LEN_CAPABLE_ACK 20

#define assert_len(target, end)   \
  if ((void *)(target + 1) > end) \
    return XDP_DROP;

struct service_key
{
  __u8 vip[16];
  __u16 port;
};

struct service_info
{
  __u32 id;
  __u8 src[16];
};

struct backend_info
{
  __u8 dst[16];
};

struct subflow_cache_key
{
  __u8 s_addr[16];
  __u16 s_port;
  __u8 d_addr[16];
  __u16 d_port;
};

struct subflow_cache_info
{
  __u8 src[16];
  __u8 dst[16];
};

struct bpf_map_def SEC("maps") services = {
    .type = BPF_MAP_TYPE_HASH,
    .key_size = sizeof(struct service_key),
    .value_size = sizeof(struct service_info),
    .max_entries = SERVICE_MAP_SIZE,
};

struct bpf_map_def SEC("maps") backends = {
    .type = BPF_MAP_TYPE_ARRAY,
    .key_size = sizeof(__u32),
    .value_size = sizeof(struct backend_info),
    .max_entries = BACKEND_ARRAY_SIZE * SERVICE_MAP_SIZE,
};

struct bpf_map_def SEC("maps") backends_len = {
    .type = BPF_MAP_TYPE_ARRAY,
    .key_size = sizeof(__u32),
    .value_size = sizeof(__u32),
    .max_entries = SERVICE_MAP_SIZE,
};

struct bpf_map_def SEC("maps") xsks_map = {
    .type = BPF_MAP_TYPE_XSKMAP,
    .key_size = sizeof(__u32),
    .value_size = sizeof(__u32),
    .max_entries = 64,
};

struct bpf_map_def SEC("maps") subflow_cache = {
    .type = BPF_MAP_TYPE_LRU_HASH,
    .key_size = sizeof(struct subflow_cache_key),
    .value_size = sizeof(struct subflow_cache_info),
    .max_entries = SUBFLOW_CACHE_SIZE,
};

static inline int swap_mac(struct ethhdr *eth)
{
  unsigned char tmp[ETH_ALEN];

  memcpy(tmp, eth->h_source, ETH_ALEN);
  memcpy(eth->h_source, eth->h_dest, ETH_ALEN);
  memcpy(eth->h_dest, tmp, ETH_ALEN);

  return 0;
}

static inline __u32 hash_tuples(struct ip6_hdr *ip6, struct tcphdr *tcp)
{
  __u32 hash;
  hash = jhash_1word(tcp->source, 0xfeedfeed);
  hash = jhash2(ip6->ip6_src.in6_u.u6_addr32, 4, hash);
  return hash;
}

static inline int forward(struct service_info *service, int backend_priv_index, struct ethhdr *eth, struct ip6_hdr *ip6ip6)
{
  struct backend_info *backend;
  __u32 backend_index = 0;

  backend_index = BACKEND_ARRAY_SIZE * service->id + backend_priv_index;
  backend = bpf_map_lookup_elem(&backends, &backend_index);
  if (!backend)
    return -1;

  swap_mac(eth);
  memcpy(ip6ip6->ip6_dst.in6_u.u6_addr8, backend->dst, sizeof(__u8) * 16);
  memcpy(ip6ip6->ip6_src.in6_u.u6_addr8, service->src, sizeof(__u8) * 16);

  return 0;
}

static inline int process_tcpopt(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6, struct tcphdr *tcp)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct service_key skey = {};
  struct service_info *service;
  int opt_len = 4 * tcp->doff - sizeof(struct tcphdr);
  void *opt_end = nxt_ptr + opt_len;
  __u32 index = ctx->rx_queue_index;
  __u8 opcode;
  __u8 opsize;
  __u8 subtype;
  __u32 hash;
  __u32 *backend_len;

  if (nxt_ptr + opt_len > data_end)
    return XDP_DROP;

  memcpy(skey.vip, ip6->ip6_dst.in6_u.u6_addr8, sizeof(__u8) * 16);
  skey.port = bpf_ntohs(tcp->dest);

  service = bpf_map_lookup_elem(&services, &skey);
  if (!service)
    return XDP_DROP;

  for (__u8 i = 0; i < MAX_TCPOPT_LEN; i++)
  {
    if (nxt_ptr + 1 > opt_end)
      break;

    if (nxt_ptr + 1 > data_end)
      break;
    opcode = *(__u8 *)nxt_ptr;

    if (opcode == TCPOPT_EOL)
      break;
    if (opcode == TCPOPT_NOP)
    {
      nxt_ptr++;
      continue;
    }

    if (nxt_ptr + 2 > data_end)
      return XDP_DROP;
    opsize = *(__u8 *)(nxt_ptr + 1);

    if (opsize < 2)
      return XDP_DROP;

    if (nxt_ptr + opsize > data_end)
      return XDP_DROP;

    if (opcode == TCPOPT_MPTCP)
    {
      if (nxt_ptr + 3 > data_end)
        return XDP_DROP;
      subtype = *(__u8 *)(nxt_ptr + 2) >> 4;
      switch (subtype)
      {
      case MPTCP_SUB_JOIN:
        if (bpf_map_lookup_elem(&xsks_map, &index))
          return bpf_redirect_map(&xsks_map, index, 0);
        return XDP_DROP;
      }
    }

    nxt_ptr += opsize;
  }

  hash = hash_tuples(ip6, tcp);
  backend_len = bpf_map_lookup_elem(&backends_len, &service->id);
  if (!backend_len)
    return XDP_DROP;
  if (forward(service, hash % *backend_len, eth, ip6ip6))
    return XDP_DROP;
  return XDP_TX;
}

static inline int process_tcphdr(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct tcphdr *tcp = (struct tcphdr *)nxt_ptr;
  struct subflow_cache_key cache_key = {};
  struct subflow_cache_info *cache;

  assert_len(tcp, data_end);

  memcpy(cache_key.d_addr, ip6->ip6_dst.in6_u.u6_addr8, sizeof(__u8) * 16);
  memcpy(cache_key.s_addr, ip6->ip6_src.in6_u.u6_addr8, sizeof(__u8) * 16);
  cache_key.d_port = bpf_ntohs(tcp->dest);
  cache_key.s_port = bpf_ntohs(tcp->source);

  cache = bpf_map_lookup_elem(&subflow_cache, &cache_key);
  if (cache)
  {
    swap_mac(eth);
    memcpy(ip6ip6->ip6_dst.in6_u.u6_addr8, cache->dst, sizeof(__u8) * 16);
    memcpy(ip6ip6->ip6_src.in6_u.u6_addr8, cache->src, sizeof(__u8) * 16);

    return XDP_TX;
  }

  return process_tcpopt(ctx, tcp + 1, eth, ip6ip6, ip6, tcp);
}

static inline int process_ip6hdr(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct ip6_hdr *ip6 = (struct ip6_hdr *)nxt_ptr;

  assert_len(ip6, data_end);

  if (ip6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_TCP)
    return XDP_PASS;

  return process_tcphdr(ctx, ip6 + 1, eth, ip6ip6, ip6);
}

static inline int process_ip6ip6hdr(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct ip6_hdr *ip6ip6 = (struct ip6_hdr *)nxt_ptr;

  assert_len(ip6ip6, data_end);

  if (ip6ip6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_IPV6)
    return XDP_PASS;

  return process_ip6hdr(ctx, ip6ip6 + 1, eth, ip6ip6);
}

static inline int process_ethhdr(struct xdp_md *ctx)
{
  void *data_end = (void *)(long)ctx->data_end;
  void *data = (void *)(long)ctx->data;
  struct ethhdr *eth = (struct ethhdr *)data;

  assert_len(eth, data_end);

  if (eth->h_proto != bpf_ntohs(ETH_P_IPV6))
    return XDP_PASS;

  return process_ip6ip6hdr(ctx, eth + 1, eth);
}

SEC("xdp")
int mptcp_proxy(struct xdp_md *ctx)
{
  return process_ethhdr(ctx);
}

char _license[] SEC("license") = "GPL";
