package models

import (
	"errors"
	"strings"

	"golang.org/x/crypto/bcrypt"
	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
)

var (
	// ErrSubdomainTaken is returned when attempting to create a
	// Company with a subdomain that is not available.
	ErrSubdomainTaken = errors.New("Subdomain is unavailable.")
	// ErrInvalidCredentials is returned when an authentication
	// attempt fails.
	ErrInvalidCredentials = errors.New("Invalid credentials.")
	// ErrUserExists is returned when an e-mail address is taken.
	ErrUserExists = errors.New("User already exists.")
)

const (
	passwordCost = 10
	userKind     = "User"
)

const (
	// RoleMain is the role of Company owners.
	RoleMain = "main"
	// RoleManager is the role of "admin" users within a Company.
	RoleManager = "manager"
	// RoleUser is the role of standard Company members.
	RoleUser = "user"
)

// Workday represents a User's working hours on a specific day of the
// week.  The empty Workday symbolizes a day off.
type Workday struct {
	Start int `json:"start"`
	End   int `json:"end"`
}

// Workdays represents a User's work week.
type Workdays struct {
	Monday    Workday `json:"monday"`
	Tuesday   Workday `json:"tuesday"`
	Wednesday Workday `json:"wednesday"`
	Thursday  Workday `json:"thursday"`
	Friday    Workday `json:"friday"`
	Saturday  Workday `json:"saturday"`
	Sunday    Workday `json:"sunday"`
}

// User represents an account belonging to a Company.  Every User has
// a Company as an ancestor in its Key.
type User struct {
	Company *datastore.Key `json:"-"`

	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"-"`
	Role     string `json:"role"`

	Timezone string   `json:"timezone"`
	Workdays Workdays `json:"workdays"`

	Avatar     string            `json:"avatar"`
	AvatarFile appengine.BlobKey `json:"-"`

	Times
}

// NewUser creates an empty User, ensuring that its Times properties
// are initialized correctly.
func NewUser() *User {
	user := User{}
	user.Role = RoleUser
	user.initTimes()
	return &user
}

// NewUserKey creates fully-qualified datastore keys for Users.
func NewUserKey(
	ctx context.Context,
	parent *datastore.Key, email string,
) *datastore.Key {
	return datastore.NewKey(ctx, userKind, strings.ToLower(email), 0, parent)
}

// Key is a helper function for building a User's key.
func (u *User) Key(ctx context.Context) *datastore.Key {
	return NewUserKey(ctx, u.Company, u.Email)
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
	user.Role = RoleMain

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
	if err := datastore.Get(ctx, userKey, &user); err != datastore.ErrNoSuchEntity {
		return nil, ErrUserExists
	}

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

	user, err := GetUser(ctx, company, email)
	if err != nil {
		if err == datastore.ErrNoSuchEntity {
			return nil, ErrInvalidCredentials
		}

		return nil, err
	}

	if err := user.CheckPassword(password); err != nil {
		return nil, ErrInvalidCredentials
	}

	return user, nil
}

// FindUsers returns a query that will retrieve all the users
// belonging to the given company.
func FindUsers(company *datastore.Key) *datastore.Query {
	return datastore.NewQuery(userKind).Ancestor(company)
}

// GetUser returns a user belonging to a given company by e-mail
// address.
func GetUser(ctx context.Context, company *datastore.Key, email string) (*User, error) {
	var user User
	if err := datastore.Get(ctx, NewUserKey(ctx, company, email), &user); err != nil {
		return nil, err
	}

	return &user, nil
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

// Put saves the User to Datastore.
func (u *User) Put(ctx context.Context) (*datastore.Key, error) {
	return datastore.Put(ctx, u.Key(ctx), u)
}
