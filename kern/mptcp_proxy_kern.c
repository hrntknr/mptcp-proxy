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

#define IPPROTO_IPV6_OPTS 60

#define SERVICE_MAP_SIZE 64

struct service_key
{
  __u8 addr[16];
  __u16 port;
};

struct service_info
{
  __u8 dst[16];
  __u8 src[16];
};

struct bpf_map_def SEC("maps") services = {
    .type = BPF_MAP_TYPE_ARRAY_OF_MAPS,
    .key_size = sizeof(struct service_key),
    .value_size = sizeof(struct service_info),
    .max_entries = SERVICE_MAP_SIZE,
};

static inline int swap_mac(struct xdp_md *ctx, struct ethhdr *eth)
{
  unsigned char tmp[ETH_ALEN];

  memcpy(tmp, eth->h_source, ETH_ALEN);
  memcpy(eth->h_source, eth->h_dest, ETH_ALEN);
  memcpy(eth->h_dest, tmp, ETH_ALEN);

  return 0;
}

static inline int process_tcphdr(struct xdp_md *ctx, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct tcphdr *tcp = (struct tcphdr *)(ip6 + 1);
  struct service_key skey = {};
  struct service_info *sinfo;
  __u64 index = 0;
  struct service_info *backend;

  assert_len(tcp, data_end);

  swap_mac(ctx, eth);

  memcpy(skey.addr, ip6->ip6_dst.in6_u.u6_addr8, sizeof(__u8) * 16);
  skey.port = bpf_ntohs(tcp->dest);

  sinfo = bpf_map_lookup_elem(&services, &skey);
  if (!sinfo)
    return XDP_DROP;

  backend = bpf_map_lookup_elem(sinfo, &index);
  if (!backend)
    return XDP_DROP;

  memcpy(ip6ip6->ip6_dst.in6_u.u6_addr8, backend->dst, sizeof(__u8) * 16);
  memcpy(ip6ip6->ip6_src.in6_u.u6_addr8, backend->src, sizeof(__u8) * 16);

  return XDP_TX;
}

static inline int process_ip6hdr(struct xdp_md *ctx, struct ethhdr *eth, struct ip6_hdr *ip6ip6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct ip6_hdr *ip6 = ip6ip6 + 1;

  assert_len(ip6, data_end);

  if (ip6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_TCP)
    return XDP_PASS;

  return process_tcphdr(ctx, eth, ip6ip6, ip6);
}

static inline int process_ip6ip6hdr(struct xdp_md *ctx, struct ethhdr *eth)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct ip6_hdr *ip6ip6 = (struct ip6_hdr *)(eth + 1);

  assert_len(ip6ip6, data_end);

  if (ip6ip6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_IPV6_OPTS)
    return XDP_PASS;

  return process_ip6hdr(ctx, eth, ip6ip6);
}

static inline int process_ethhdr(struct xdp_md *ctx)
{
  void *data_end = (void *)(long)ctx->data_end;
  void *data = (void *)(long)ctx->data;
  struct ethhdr *eth = (struct ethhdr *)data;

  assert_len(eth, data_end);

  if (eth->h_proto != bpf_ntohs(ETH_P_IPV6))
    return XDP_PASS;

  return process_ip6ip6hdr(ctx, eth);
}

SEC("xdp")
int mptcp_proxy(struct xdp_md *ctx)
{
  return process_ethhdr(ctx);
}

char _license[] SEC("license") = "GPL";
