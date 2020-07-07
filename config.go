package main

import (
	"github.com/spf13/viper"
)

type Config struct {
	Iface   string
	XdpProg string `mapstructure:"xdp_prog"`
}

var config Config

func init() {
	viper.SetConfigName("config.yml")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("/etc/mptcp-proxy/")
	viper.AddConfigPath("$HOME/.mptcp-proxy")
	viper.AddConfigPath(".")

	viper.SetDefault("iface", "eth0")
	viper.SetDefault("xdp_prog", "kern/mptcp_proxy_kern.o")

	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	if err := viper.Unmarshal(&config); err != nil {
		panic(err)
	}
}
