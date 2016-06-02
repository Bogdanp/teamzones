package utils

import (
	"net/http"

	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/aetest"
)

// AEContext is a helper for generating new AE test contexts.
func AEContext() (context.Context, func() error, error) {
	inst, err := aetest.NewInstance(nil)
	if err != nil {
		return nil, nil, err
	}

	req, err := inst.NewRequest(http.MethodGet, "/", nil)
	if err != nil {
		return nil, nil, err
	}

	ctx := appengine.NewContext(req)
	return ctx, inst.Close, nil
}
