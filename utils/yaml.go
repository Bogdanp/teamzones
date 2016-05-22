package utils

import (
	"io/ioutil"

	"gopkg.in/yaml.v2"
)

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
