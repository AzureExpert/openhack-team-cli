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
	"strconv"

	"github.com/Azure-Samples/openhack-team-cli/pkg/authorization"
	"github.com/Azure-Samples/openhack-team-cli/pkg/graph"
	"github.com/Azure-Samples/openhack-team-cli/pkg/helpers"
	"github.com/Azure-Samples/openhack-team-cli/pkg/resources"
	"github.com/Azure/go-autorest/autorest/to"
	log "github.com/Sirupsen/logrus"

	"github.com/spf13/cobra"
)

var (
	numberspn int
	prefixspn string
)

// spnCmd represents the spn command
var spnCmd = &cobra.Command{
	Use:   "spn",
	Short: "provision an amount of spn",
	Long:  ``,
	Run:   createSPN,
}

func init() {
	rootCmd.AddCommand(spnCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// spnCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// spnCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	spnCmd.Flags().StringVarP(&prefixspn, "prefix", "p", "team", "Prefix string to generate the name of each SPN")
	spnCmd.Flags().IntVarP(&numberspn, "number", "n", 0, "Number of SPN to create")
}

// TODO : Use the global location switch, right it is hardcoded
func createSPN(cmd *cobra.Command, args []string) {

	defer resources.Cleanup(context.Background())

	logFields := log.Fields{
		"prefix":   prefixspn,
		"count":    numberspn,
		"location": location,
	}
	log.WithFields(logFields).Debug(
		"provision spn cmd called",
	)

	for index := 101; index <= number+100; index++ {
		done := make(chan bool)
		go func() {
			tags := map[string]*string{
				"openhack": to.StringPtr("devops"),
				"team":     to.StringPtr(strconv.Itoa(index)),
			}

			ctx := context.Background()

			app, err := graphrbac.CreateADApplication(ctx)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("ad app created")

			sp, err := graphrbac.CreateServicePrincipal(ctx, *app.AppID)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("service principal created")

			_, err = graphrbac.AddClientSecret(ctx, *app.ObjectID)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("added client secret")

			helpers.SetResourceGroupName("CreateServicePrincipal")
			_, err = resources.CreateGroup(ctx, prefix+strconv.Itoa(index), location, tags)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("created resource group")

			list, err := authorization.ListRoles(ctx, "roleName eq 'Contributor'")
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("list contributor role definition, with resource group scope")

			_, err = authorization.AssignRole(ctx, *sp.ObjectID, *list.Values()[0].ID)
			if err != nil {
				helpers.PrintAndLog(err.Error())
			}
			helpers.PrintAndLog("create role definition")

			// if !helpers.KeepResources() {
			// 	_, err = resources.DeleteGroup(ctx, helpers.ResourceGroupName())
			// 	if err != nil {
			// 		helpers.PrintAndLog(err.Error())
			// 	}

			// 	_, err = DeleteADApplication(ctx, *app.ObjectID)
			// 	if err != nil {
			// 		helpers.PrintAndLog(err.Error())
			// 	}
			// }

			log.WithFields(log.Fields{
				"name":     prefix + strconv.Itoa(index),
				"number":   index - 100,
				"location": location,
			}).Debug("SPN Created / Updated")
			done <- true
		}()
		<-done
	}
}
