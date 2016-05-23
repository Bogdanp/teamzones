package utils

// Country is the name of a Country and its ALPHA-2 code.
type Country struct {
	Name string
	Code string
	VAT  int `json:"VAT,omitempty"`
}

// Countries is the list of ISO 3166-2 countries and their ALPHA-2 codes.
var Countries []Country

// VATCountries is the list of EU members that charge VAT.
var VATCountries []Country

func init() {
	Countries = make([]Country, 249)
	LoadJSON("data/countries.json", &Countries)

	i := 0
	VATCountries = make([]Country, 28)
	for _, c := range Countries {
		if c.VAT != 0 {
			VATCountries[i] = c

			i++
		}
	}
}
