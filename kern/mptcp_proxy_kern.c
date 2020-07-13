#include <string.h>
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ipv6.h>
#include <netinet/ip6.h>
#include <linux/tcp.h>
#include <arpa/inet.h>

#include "bpf_helpers.h"
#include "bpf_endian.h"

#define assert_len(target, end)   \
  if ((void *)(target + 1) > end) \
    return XDP_DROP;

#define SERVICE_MAP_SIZE 64
#define BACKEND_ARRAY_SIZE 64

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

static inline int swap_mac(struct xdp_md *ctx, struct ethhdr *eth)
{
  unsigned char tmp[ETH_ALEN];

  memcpy(tmp, eth->h_source, ETH_ALEN);
  memcpy(eth->h_source, eth->h_dest, ETH_ALEN);
  memcpy(eth->h_dest, tmp, ETH_ALEN);

  return 0;
}

static inline int process_tcphdr(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct tcphdr *tcp = (struct tcphdr *)nxt_ptr;

  struct service_key skey = {};
  struct service_info *service;
  struct backend_info *backend;
  __u32 backend_index = 0;

  assert_len(tcp, data_end);

  swap_mac(ctx, eth);

  memcpy(skey.vip, ip6->ip6_dst.in6_u.u6_addr8, sizeof(__u8) * 16);
  skey.port = bpf_ntohs(tcp->dest);

  service = bpf_map_lookup_elem(&services, &skey);
  if (!service)
    return XDP_DROP;

  backend_index = BACKEND_ARRAY_SIZE * service->id + 0;
  backend = bpf_map_lookup_elem(&backends, &backend_index);
  if (!backend)
    return XDP_DROP;

  memcpy(ip6ip6->ip6_dst.in6_u.u6_addr8, backend->dst, sizeof(__u8) * 16);
  memcpy(ip6ip6->ip6_src.in6_u.u6_addr8, service->src, sizeof(__u8) * 16);

  return XDP_TX;
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
  void *new_nxt_ptr;

  assert_len(ip6ip6, data_end);

  if (ip6ip6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_DSTOPTS)
    return XDP_PASS;

  struct ip6_dest *ip6ip6_dest = (struct ip6_dest *)(ip6ip6 + 1);
  assert_len(ip6ip6_dest, data_end);

  new_nxt_ptr = (void *)(ip6ip6_dest + 1);
  new_nxt_ptr = new_nxt_ptr + 6 + ip6ip6_dest->ip6d_len * 8;

  if (ip6ip6_dest->ip6d_nxt != IPPROTO_IPV6)
    return XDP_PASS;

  return process_ip6hdr(ctx, new_nxt_ptr, eth, ip6ip6);
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
