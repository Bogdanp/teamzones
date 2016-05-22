package utils

import (
	"encoding/json"
	"io/ioutil"
	"os"

	"gopkg.in/yaml.v2"
)

// LoadJSON parses and loads JSON data from a file into a struct.
// This function panics on error.
func LoadJSON(filename string, output interface{}) {
	f, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	if err := json.NewDecoder(f).Decode(output); err != nil {
		panic(err)
	}
}

// LoadYAML parses and loads YAML data from a file into a struct.
// This function panics on error.
func LoadYAML(filename string, output interface{}) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	if err := yaml.Unmarshal(data, output); err != nil {
		panic(err)
	}
}
