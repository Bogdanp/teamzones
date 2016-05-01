package models

import (
	"errors"

	"golang.org/x/crypto/bcrypt"
	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
)

var (
	// ErrSubdomainTaken is returned when attempting to create a
	// Company with a subdomain that is not available.
	ErrSubdomainTaken = errors.New("Subdomain is unavailable.")
	// ErrInvalidCredentials is returned when an authentication
	// attempt fails.
	ErrInvalidCredentials = errors.New("Invalid credentials.")
)

const (
	passwordCost = 10
	userKind     = "User"
)

// User represents an account belonging to a Company.  Every User has
// a Company as an ancestor in its Key.
type User struct {
	Company *datastore.Key `json:"-"`

	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"-"`
	Avatar   string `json:"avatar"`
	Timezone string `json:"timezone"`

	Times
}

// NewUser creates an empty User, ensuring that its Times properties
// are initialized correctly.
func NewUser() *User {
	user := User{}
	user.Avatar = "/static/images/default-avatar.png"
	user.initTimes()
	return &user
}

// NewUserKey creates fully-qualified datastore keys for Users.
func NewUserKey(
	ctx context.Context,
	parent *datastore.Key, email string,
) *datastore.Key {
	return datastore.NewKey(ctx, userKind, email, 0, parent)
}

// CreateMainUser transactionally creates the initial Company and User
// pair for a company.
func CreateMainUser(
	ctx context.Context,
	companyName, companySubdomain, name, email, password, timezone string,
) (*Company, *User, error) {

	company := NewCompany()
	companyKey := NewCompanyKey(ctx, companySubdomain)
	if err := datastore.Get(ctx, companyKey, &company); err != datastore.ErrNoSuchEntity {
		return nil, nil, ErrSubdomainTaken
	}

	company.Name = companyName
	company.Subdomain = companySubdomain

	user := NewUser()
	userKey := NewUserKey(ctx, companyKey, email)
	user.Company = companyKey
	user.Name = name
	user.Email = email
	user.SetPassword(password)
	user.Timezone = timezone

	err := datastore.RunInTransaction(ctx, func(ctx context.Context) error {
		_, err := datastore.Put(ctx, companyKey, company)
		if err != nil {
			return err
		}

		_, err = datastore.Put(ctx, userKey, user)
		return err
	}, nil)

	return company, user, err
}

// CreateUser creates team members.
func CreateUser(
	ctx context.Context,
	companyKey *datastore.Key,
	name, email, password, timezone string,
) (*User, error) {

	user := NewUser()
	userKey := NewUserKey(ctx, companyKey, email)
	user.Company = companyKey
	user.Name = name
	user.Email = email
	user.SetPassword(password)
	user.Timezone = timezone
	if _, err := datastore.Put(ctx, userKey, user); err != nil {
		return nil, err
	}

	return user, nil
}

// SetPassword updates the User's password by hashing the given string.
func (u *User) SetPassword(password string) error {
	hashed, error := bcrypt.GenerateFromPassword([]byte(password), passwordCost)
	u.Password = string(hashed)
	return error
}

// CheckPassword compares the User's hashed password against a given
// password.  If nil is returned, the passwords are the same.
func (u *User) CheckPassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
}

// Authenticate attempts to read a user from the datastore by e-mail
// and, if successful, validates that the given password is correct.
func Authenticate(
	ctx context.Context,
	company *datastore.Key,
	email, password string,
) (*User, error) {

	var user User
	if err := datastore.Get(ctx, NewUserKey(ctx, company, email), &user); err != nil {
		if err == datastore.ErrNoSuchEntity {
			return nil, ErrInvalidCredentials
		}

		return nil, err
	}

	if err := user.CheckPassword(password); err != nil {
		return nil, ErrInvalidCredentials
	}

	return &user, nil
}

// FindUsers returns a query that will retrieve all the users
// belonging to the given company.
func FindUsers(company *datastore.Key) *datastore.Query {
	return datastore.NewQuery(userKind).Ancestor(company)
}

// Load tells datastore how to deserialize Users when reading them.
func (u *User) Load(p []datastore.Property) error {
	return datastore.LoadStruct(u, p)
}

// Save tells datastore how to serialize Users before storing them.
// This is used to keep Users' Times up to date.
func (u *User) Save() ([]datastore.Property, error) {
	u.updateTimes()

	return datastore.SaveStruct(u)
}
