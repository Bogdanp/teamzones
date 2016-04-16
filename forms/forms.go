package forms

import (
	"errors"
	"fmt"
	"net/http"
	"reflect"
	"strings"
)

// Validator is an alias for functions from string to error.  They are
// used to ensure that the values of fields are what we expect them to
// be.
type Validator func(string) error

// Field represents a field on a form.  They are used to perform form
// validation and to make rendering forms easy.
type Field struct {
	Name       string
	Label      string
	Value      string
	Optional   bool
	Errors     []string
	Validators []Validator
}

// Bind binds form data to a struct from a Request, validating
// each field.
func Bind(req *http.Request, form interface{}) bool {
	ok := true
	sv := reflect.ValueOf(form).Elem()
	for i := 0; i < sv.NumField(); i++ {
		fv := sv.Field(i)

		var errors []string
		value := req.FormValue(fv.FieldByName("Name").String())
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

// Email validates that the Field's value is an e-mail address.
func Email(value string) error {
	if len(value) < 3 || !strings.Contains(value, "@") {
		return errors.New("Please enter a valid e-mail address.")
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

// MaxLength validates that the Field's value is at least n characters long.
func MaxLength(n int) Validator {
	return func(value string) error {
		if len(value) > n {
			return fmt.Errorf("This field can contain at most %d characters.", n)
		}

		return nil
	}
}
