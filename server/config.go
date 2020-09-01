package main

import (
	"github.com/spf13/viper"
)

type Config struct {
	Iface       string `mapstructure:"iface"`
	Dst         string `mapstructure:"dst"`
	Src         string `mapstructure:"src"`
	BPFFilter   string `mapstructure:"bpf_filter"`
	Redus       string `mapstructure:"redis"`
	JoinTimeout string `mapstructure:"join_timeout"`
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
	viper.SetDefault("redis", "localhost:6379")
	viper.SetDefault("join_timeout", "10s")

	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	if err := viper.Unmarshal(&config); err != nil {
		panic(err)
	}
}
