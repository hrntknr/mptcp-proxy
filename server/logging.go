package main

import (
	"os"

	log "github.com/sirupsen/logrus"
)

func init() {
	lvl, err := log.ParseLevel(os.Getenv("LOG_LEVEL"))
	if err != nil {
		log.SetLevel(log.InfoLevel)
	} else {
		log.SetLevel(lvl)
	}
}
