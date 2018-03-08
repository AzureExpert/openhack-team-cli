package helpers

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/Azure/go-autorest/autorest/utils"
)

// GetEnvVarOrExit returns the value of specified environment variable or terminates if it's not defined.
func GetEnvVarOrExit(varName string) string {
	value := os.Getenv(varName)
	if value == "" {
		fmt.Printf("Missing environment variable '%s'\n", varName)
		os.Exit(1)
	}

	return value
}

// onErrorFail prints a failure message and exits the program if err is not nil.
func OnErrorFail(err error, message string) {
	if err != nil {
		fmt.Printf("%s: %s\n", message, err)
		os.Exit(1)
	}
}

// PrintAndLog writes to stdout and to a logger.
func PrintAndLog(message string) {
	log.Println(message)
	fmt.Println(message)
}

// GetRandomLetterSequence returns a sequence of English characters of length n.
func GetRandomLetterSequence(n int) string {
	rand.Seed(time.Now().UTC().UnixNano())
	letters := []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func contains(array []string, element string) bool {
	for _, e := range array {
		if e == element {
			return true
		}
	}
	return false
}

// UserAgent return the string to be appended to user agent header
func UserAgent() string {
	return "samples " + utils.GetCommit()
}
