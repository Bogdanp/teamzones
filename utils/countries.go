package utils

// Country is the name of a Country and its ALPHA-2 code.
type Country struct {
	Name string
	Code string
}

// Countries is the list of ISO 3166-2 countries and their ALPHA-2 codes.
var Countries = loadCountries()

func loadCountries() []Country {
	countries := make([]Country, 249)
	LoadJSON("data/countries.json", &countries)
	return countries
}
