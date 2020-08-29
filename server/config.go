package main

import (
	"github.com/spf13/viper"
)

type Config struct {
	Iface        string   `mapstructure:"iface"`
	BackendIndex int      `mapstructure:"backend_index"`
	BPFFilter    string   `mapstructure:"bpf_filter"`
	Memcached    []string `mapstructure:"memcached"`
}

var config Config

func init() {
	viper.SetConfigName("config.yml")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("/etc/mptcp-server/")
	viper.AddConfigPath("$HOME/.mptcp-server")
	viper.AddConfigPath(".")

	viper.SetDefault("iface", "eth0")
	viper.SetDefault("xdp_prog", "./mptcp_server_kern.o")
	viper.SetDefault("memcached", []string{"localhost:11211"})

	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	if err := viper.Unmarshal(&config); err != nil {
		panic(err)
	}
}
