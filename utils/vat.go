package utils

import (
	"bytes"
	"encoding/xml"
	"io"
	"regexp"
	"strings"
	"text/template"
	"time"

	"github.com/pkg/errors"
	"golang.org/x/net/context"
	"google.golang.org/appengine/memcache"
	"google.golang.org/appengine/urlfetch"
)

const (
	vatServiceURL      = "http://ec.europa.eu/taxation_customs/vies/services/checkVatService"
	vatServiceEnvelope = `
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://schemas.conversesolutions.com/xsd/dmticta/v1">
<soapenv:Header/>
<soapenv:Body>
  <checkVat xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
    <countryCode>{{.CountryCode}}</countryCode>
    <vatNumber>{{.VATID}}</vatNumber>
  </checkVat>
</soapenv:Body>
</soapenv:Envelope>
`
)

// CheckVAT returns true if the given VATID is valid.
func CheckVAT(ctx context.Context, VATID string) bool {
	var res bool

	k := "CheckVAT:" + VATID
	if _, err := memcache.JSON.Get(ctx, k, &res); err == nil {
		return res
	}

	res = checkVAT(ctx, VATID)
	memcache.JSON.Set(ctx, &memcache.Item{
		Key:        k,
		Object:     res,
		Expiration: 8 * time.Hour,
	})

	return res
}

func checkVAT(ctx context.Context, VATID string) bool {
	VATID = sanitizeVATID(VATID)

	e, err := buildVATEnvelope(VATID)
	if err != nil {
		return false
	}

	c := urlfetch.Client(ctx)
	r, err := c.Post(vatServiceURL, "text/xml;charset=UTF-8", e)
	if err != nil {
		return false
	}
	defer r.Body.Close()

	var data struct {
		XMLName xml.Name `xml:"Envelope"`
		Soap    struct {
			XMLName xml.Name `xml:"Body"`
			Soap    struct {
				XMLName xml.Name `xml:"checkVatResponse"`
				Valid   bool     `xml:"valid"`
			}
		}
	}

	if err := xml.NewDecoder(r.Body).Decode(&data); err != nil {
		return false
	}

	return data.Soap.Soap.Valid
}

func buildVATEnvelope(VATID string) (io.Reader, error) {
	if len(VATID) < 3 {
		return nil, errors.New("invalid VAT ID")
	}

	t, err := template.New("envelope").Parse(vatServiceEnvelope)
	if err != nil {
		return nil, errors.Wrap(err, "buildVATEnvelope failed to parse template: %v")
	}

	var buf bytes.Buffer

	err = t.Execute(&buf, struct {
		CountryCode string
		VATID       string
	}{
		CountryCode: VATID[0:2],
		VATID:       VATID[2:],
	})
	if err != nil {
		return nil, err
	}

	return &buf, nil
}

func sanitizeVATID(VATID string) string {
	return regexp.MustCompile(" ").ReplaceAllString(strings.TrimSpace(VATID), "")
}
