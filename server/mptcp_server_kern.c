#include <string.h>
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ipv6.h>
#include <netinet/ip6.h>
#include <linux/tcp.h>
#include <arpa/inet.h>

#include "bpf_helpers.h"
#include "bpf_endian.h"
#include "common.h"

struct bpf_map_def SEC("maps") new_session ={
    .type = BPF_MAP_TYPE_PERF_EVENT_ARRAY,
    .key_size = sizeof(int),
    .value_size = sizeof(int),
    .max_entries = PERF_SIZE,
};

static inline int process_tcpopt(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6, struct tcphdr *tcp)
{
    void *data_end = (void *)(long)ctx->data_end;
    // struct new_session_notice notice = {};
    int opt_len = 4 * tcp->doff - sizeof(struct tcphdr);
    void *opt_end = nxt_ptr + opt_len;
    __u64 client_key;
    __u8 opcode;
    __u8 opsize;
    __u8 subtype;

    if (nxt_ptr + opt_len > data_end)
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
            case MPTCP_SUB_CAPABLE:
                if (opsize != MPTCP_SUB_LEN_CAPABLE_ACK)
                    return XDP_PASS;
                if (nxt_ptr + MPTCP_SUB_LEN_CAPABLE_ACK > data_end)
                    return XDP_DROP;

                client_key = *(__u64 *)(nxt_ptr + 4);
                bpf_printk("%d\n", client_key);
                return XDP_PASS;
            }
        }

        nxt_ptr += opsize;
    }

    return XDP_PASS;
}

static inline int process_tcphdr(struct xdp_md *ctx, void *nxt_ptr, struct ethhdr *eth, struct ip6_hdr *ip6ip6, struct ip6_hdr *ip6)
{
    void *data_end = (void *)(long)ctx->data_end;
    struct tcphdr *tcp = (struct tcphdr *)nxt_ptr;

    assert_len(tcp, data_end);

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
int mptcp_server(struct xdp_md *ctx)
{
    return process_ethhdr(ctx);
}

char _license[] SEC("license") = "GPL";
