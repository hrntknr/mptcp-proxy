package main

import (
	"github.com/spf13/viper"
)

type Config struct {
	Iface     string    `mapstructure:"iface"`
	QueueID   int       `mapstructure:"queue_id"`
	XdpProg   string    `mapstructure:"xdp_prog"`
	Services  []Service `mapstructure:"services"`
	Memcached []string  `mapstructure:"memcached"`
}

type Service struct {
	Port     uint16   `mapstructure:"port"`
	VIP      string   `mapstructure:"vip"`
	Backends []string `mapstructure:"backends"`
	Src      string   `mapstructure:"src"`
}

var config Config

func init() {
	viper.SetConfigName("config.yml")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("/etc/mptcp-proxy/")
	viper.AddConfigPath("$HOME/.mptcp-proxy")
	viper.AddConfigPath(".")

	viper.SetDefault("iface", "eth0")
	viper.SetDefault("queue_id", "0")
	viper.SetDefault("xdp_prog", "./mptcp_proxy_kern.o")
	viper.SetDefault("services", []Service{})
	viper.SetDefault("memcached", []string{"localhost:11211"})

	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	if err := viper.Unmarshal(&config); err != nil {
		panic(err)
	}
}
