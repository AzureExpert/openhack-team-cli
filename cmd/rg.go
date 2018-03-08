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

package cmd

import (
	"context"
	"fmt"
	"strconv"

	"github.com/Azure-Samples/openhack-team-cli/pkg/helpers"
	"github.com/Azure-Samples/openhack-team-cli/pkg/resources"
	"github.com/Azure/go-autorest/autorest/to"
	log "github.com/Sirupsen/logrus"

	"github.com/spf13/cobra"
)

var (
	location = "westus"

	number int
	prefix string
	toto   string
)

// rgCmd represents the rg command
var rgCmd = &cobra.Command{
	Use:   "rg",
	Short: "Manage the resource groups",
	Long:  ``,
}

var rgCreateCmd = &cobra.Command{
	Use:   "provision",
	Short: "Provision the resource groups",
	Long:  ``,
	Run:   createRG,
}

var rgDeleteCmd = &cobra.Command{
	Use:   "unprovision",
	Short: "Unprovision the resource groups",
	Long:  ``,
	Run:   deleteRG,
}

func init() {
	rootCmd.AddCommand(rgCmd)
	rgCmd.AddCommand(rgCreateCmd)
	rgCmd.AddCommand(rgDeleteCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	rgCmd.PersistentFlags().StringVar(&prefix, "foo", "f", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// rgCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	rgCreateCmd.Flags().StringVarP(&prefix, "prefix", "p", "team", "Prefix string to generate the name of each resource group")
	rgCreateCmd.Flags().IntVarP(&number, "number", "n", 0, "Number of resource group to create")
}

// TODO : Use the global location switch, right it is hardcoded
func createRG(cmd *cobra.Command, args []string) {

	defer resources.Cleanup(context.Background())

	logFields := log.Fields{
		"prefix":   prefix,
		"count":    number,
		"location": location,
	}
	log.WithFields(logFields).Debug(
		"provision rg cmd called",
	)

	for index := 101; index <= number+100; index++ {
		done := make(chan bool)
		go func() {
			tags := map[string]*string{
				"openhack": to.StringPtr("devops"),
				"team":     to.StringPtr(strconv.Itoa(index)),
			}
			_, err := resources.CreateGroup(context.Background(), prefix+strconv.Itoa(index), location, tags)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			log.WithFields(log.Fields{
				"name":     prefix + strconv.Itoa(index),
				"number":   index - 100,
				"location": location,
			}).Debug("RG Created / Updated")
			done <- true
		}()
		<-done
	}
}

// TODO : Use the global location switch, right it is hardcoded
func deleteRG(cmd *cobra.Command, args []string) {
	fmt.Printf("%s", toto)
}
