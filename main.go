// Copyright © 2018 NAME HERE <EMAIL ADDRESS>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"os"
	"strings"

	log "github.com/Sirupsen/logrus"

	"github.com/Azure-Samples/openhack-team-cli/cmd"
	"github.com/Azure-Samples/openhack-team-cli/pkg/config"
)

// This requires that the following environment vars are set:
//
// AZURE_TENANT_ID: contains your Azure Active Directory tenant ID or domain
// AZURE_CLIENT_ID: contains your Azure Active Directory Application Client ID
// AZURE_CLIENT_SECRET: contains your Azure Active Directory Application Secret
// AZURE_SUBSCRIPTION_ID: contains your Azure Subscription ID
//

func main() {
	log.SetOutput(os.Stdout)
	formatter := &log.TextFormatter{
		FullTimestamp: true,
	}
	log.SetFormatter(formatter)
	logConfig, err := config.GetLogConfig()
	if err != nil {
		log.Fatal(err)
	}
	log.SetLevel(log.InfoLevel)
	logLevel := logConfig.GetLevel()
	log.WithField(
		"logLevel",
		strings.ToUpper(logLevel.String()),
	).Info("Setting log level")
	log.SetLevel(logLevel)
	if err != nil {
		log.Fatal(err)
	}
	cmd.Execute()
}
