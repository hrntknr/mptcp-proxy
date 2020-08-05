#include <linux/types.h>

#define assert_len(target, end)   \
  if ((void *)(target + 1) > end) \
    return XDP_DROP;

#define SERVICE_MAP_SIZE 64
#define BACKEND_ARRAY_SIZE 64

#define MAX_TCPOPT_LEN 8
#define PERF_SIZE 1

#define TCPOPT_NOP 1
#define TCPOPT_EOL 0
#define TCPOPT_MPTCP 30

#define MPTCP_SUB_CAPABLE 0
#define MPTCP_SUB_JOIN 1

#define MPTCP_SUB_LEN_CAPABLE_SYN 12
#define MPTCP_SUB_LEN_CAPABLE_ACK 20

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

struct new_client_notice
{
    __u64 client_key;
    __u32 backend_index;
};

struct new_session_notice
{
    __u64 client_key;
};
