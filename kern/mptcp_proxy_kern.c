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

static inline int process_tcphdr(struct xdp_md *ctx, struct ethhdr *eth, struct ip6_hdr *ipv6)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct tcphdr *tcp = (struct tcphdr *)(ipv6 + 1);

  assert_len(tcp, data_end);

  return XDP_PASS;
}

static inline int process_ipv6hdr(struct xdp_md *ctx, struct ethhdr *eth)
{
  void *data_end = (void *)(long)ctx->data_end;
  struct ip6_hdr *ipv6 = (struct ip6_hdr *)(eth + 1);

  assert_len(ipv6, data_end);

  if (ipv6->ip6_ctlun.ip6_un1.ip6_un1_nxt != IPPROTO_TCP)
    return XDP_PASS;

  return process_tcphdr(ctx, eth, ipv6);
}

static inline int process_ethhdr(struct xdp_md *ctx)
{
  void *data_end = (void *)(long)ctx->data_end;
  void *data = (void *)(long)ctx->data;
  struct ethhdr *eth = (struct ethhdr *)data;

  assert_len(eth, data_end);

  if (eth->h_proto != bpf_ntohs(ETH_P_IPV6))
    return XDP_PASS;

  return process_ipv6hdr(ctx, eth);
}

SEC("xdp")
int mptcp_proxy(struct xdp_md *ctx)
{
  return process_ethhdr(ctx);
}

char _license[] SEC("license") = "GPL";
