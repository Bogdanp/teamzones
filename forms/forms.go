package forms

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"teamzones/utils"
)

// Validator is an alias for functions from string to error.  They are
// used to ensure that the values of fields are what we expect them to
// be.
type Validator func(string) error

// Option represents a value in a multiple-choice field (eg. a select
// field).
type Option struct {
	Value string
	Label string
}

// Field represents a field on a form.  They are used to perform form
// validation and to make rendering forms easy.
type Field struct {
	Name        string
	Label       string
	Placeholder string
	Value       string
	Values      []Option
	Optional    bool
	Errors      []string
	Validators  []Validator
	HideLabel   bool
	Attributes  map[string]string
}

func bind(lookup func(string) string, form interface{}) bool {
	ok := true
	sv := reflect.ValueOf(form).Elem()
	for i := 0; i < sv.NumField(); i++ {
		fv := sv.Field(i)

		var errors []string
		value := lookup(fv.FieldByName("Name").String())
		optional := fv.FieldByName("Optional").Bool()
		if value == "" && !optional {
			errors = append(errors, "This field is required.")
		}

		validators := fv.FieldByName("Validators").Interface().([]Validator)
		for _, validator := range validators {
			if err := validator(value); err != nil {
				errors = append(errors, err.Error())
			}
		}

		if len(errors) > 0 {
			ok = false

			fv.FieldByName("Errors").Set(reflect.ValueOf(errors))
		}

		fv.FieldByName("Value").SetString(value)
	}

	return ok
}

// Bind binds form data to a struct from a Request, validating
// each field.
func Bind(req *http.Request, form interface{}) bool {
	return bind(req.FormValue, form)
}

var dynValidators = map[string](func(interface{}, []string) error){
	"Email":     dynEmail,
	"MinLength": dynMinLength,
	"MaxLength": dynMaxLength,
}

// BindJSON binds JSON request data to a struct, validating each field.
func BindJSON(req *http.Request, data interface{}) error {
	decoder := json.NewDecoder(req.Body)
	if err := decoder.Decode(&data); err != nil {
		return err
	}

	sv := reflect.ValueOf(data).Elem()
	st := reflect.TypeOf(data).Elem()
	for i := 0; i < sv.NumField(); i++ {
		ft := st.Field(i)
		tag := ft.Tag.Get("validate")
		if tag == "" {
			continue
		}

		validators := strings.Split(tag, ",")
		for _, call := range validators {
			segments := strings.Split(call, ":")
			name := segments[0]
			args := segments[1:]
			validator, ok := dynValidators[name]
			if !ok {
				log.Fatalf("unknown validator: %v", name)
			}

			err := validator(sv.Field(i).Interface(), args)
			if err != nil {
				return fmt.Errorf("%v: %s", ft.Name, err)
			}
		}
	}

	return nil
}

// Email validates that the Field's value is an e-mail address.
func Email(value string) error {
	if len(value) < 3 || len(value) > 150 || !strings.Contains(value, "@") {
		return errors.New("Please enter a valid e-mail address.")
	}

	return nil
}

func dynEmail(value interface{}, _ []string) error {
	return Email(value.(string))
}

var reservedSubdomains = []string{
	"admin",
	"support",
}

// Subdomain validates that the Field's value is a subdomain.
func Subdomain(value string) error {
	for _, subdomain := range reservedSubdomains {
		if value == subdomain {
			return errors.New("The selected subdomain is reserved.")
		}
	}

	value = strings.ToLower(value)
	for _, char := range value {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
			continue
		}

		return errors.New("Subdomains may only contain letters and numbers.")
	}

	return nil
}

// MinLength validates that the Field's value is at least n characters long.
func MinLength(n int) Validator {
	return func(value string) error {
		if len(value) < n {
			return fmt.Errorf("This field must contain at least %d characters.", n)
		}

		return nil
	}
}

func dynMinLength(value interface{}, args []string) error {
	n, err := strconv.Atoi(args[0])
	if err != nil {
		log.Fatalf("invalid length: %q", args[0])
	}

	return MinLength(n)(value.(string))
}

// MaxLength validates that the Field's value is at least n characters long.
func MaxLength(n int) Validator {
	return func(value string) error {
		if len(value) > n {
			return fmt.Errorf("This field can contain at most %d characters.", n)
		}

		return nil
	}
}

// Name validates that the Field's value is the correct name for a {First,Last} name.
func Name(value string) error {
	if len(value) < 2 || len(value) > 35 {
		return fmt.Errorf("Names must be between 2 and 35 characters long.")
	}

	return nil
}

func dynMaxLength(value interface{}, args []string) error {
	n, err := strconv.Atoi(args[0])
	if err != nil {
		log.Fatalf("invalid length: %q", args[0])
	}

	return MaxLength(n)(value.(string))
}

// Country validates that the Field's value is a valid ISO country code.
func Country(value string) error {
	for _, country := range utils.Countries {
		if country.Code == value {
			return nil
		}
	}

	return fmt.Errorf("Country %q does not exist.", value)
}

// CountryValues is the list of Options representing the set of countries.
var CountryValues = buildCountryValues()

func buildCountryValues() []Option {
	options := make([]Option, len(utils.Countries))
	for i, country := range utils.Countries {
		options[i].Value = country.Code
		options[i].Label = country.Name
	}

	return options
}
