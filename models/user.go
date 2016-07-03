package models

import (
	"errors"
	"fmt"
	"strings"
	"teamzones/utils"
	"time"

	"github.com/qedus/nds"

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
	// ErrTokenExpired is returned when a RecoveryToken has expired.
	ErrTokenExpired = errors.New("Recovery token has expired.")
)

const (
	passwordCost = 12
	userKind     = "User"
	tokenKind    = "RecoveryToken"
	tokenTTL     = 2 * time.Hour
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

	FirstName string `json:"firstName"`
	LastName  string `json:"lastName"`
	Email     string `json:"email"`
	Password  string `json:"-"`
	Role      string `json:"role"`

	Timezone string   `json:"timezone"`
	Workdays Workdays `json:"workdays"`

	Avatar     string            `json:"avatar"`
	AvatarSm   string            `json:"smallAvatar"`
	AvatarFile appengine.BlobKey `json:"-"`

	GCalendarToken *datastore.Key `json:"-"`
	GCalendarData  *datastore.Key `json:"-"`

	Times
}

// RecoveryToken represents a nonce that can be used to reset a User's
// password.  Every RecoveryToken has a Company as an ancestor in its
// Key.
type RecoveryToken struct {
	Company *datastore.Key `json:"-"`
	User    *datastore.Key `json:"-"`

	Times
}

// NewUser creates an empty User, ensuring that its Times properties
// are initialized correctly.
func NewUser() *User {
	user := User{}
	user.Role = RoleUser
	user.Workdays.Monday = Workday{9, 17}
	user.Workdays.Tuesday = Workday{9, 17}
	user.Workdays.Wednesday = Workday{9, 17}
	user.Workdays.Thursday = Workday{9, 17}
	user.Workdays.Friday = Workday{9, 17}
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
	ctx context.Context, company *Company,
	firstName, lastName, email, password, timezone string,
) (*User, error) {

	companyKey := NewCompanyKey(ctx, company.Subdomain)
	if err := nds.Get(ctx, companyKey, &company); err != datastore.ErrNoSuchEntity {
		return nil, ErrSubdomainTaken
	}

	user := NewUser()
	userKey := NewUserKey(ctx, companyKey, email)
	user.Company = companyKey
	user.FirstName = firstName
	user.LastName = lastName
	user.Email = email
	user.SetPassword(password)
	user.Timezone = timezone
	user.Role = RoleMain

	err := nds.RunInTransaction(ctx, func(ctx context.Context) error {
		_, err := nds.Put(ctx, companyKey, company)
		if err != nil {
			return err
		}

		_, err = nds.Put(ctx, userKey, user)
		return err
	}, nil)

	return user, err
}

// CreateUser creates team members.
func CreateUser(
	ctx context.Context,
	companyKey *datastore.Key,
	firstName, lastName, email, password, timezone string,
) (*User, error) {

	user := NewUser()
	userKey := NewUserKey(ctx, companyKey, email)
	if err := nds.Get(ctx, userKey, &user); err != datastore.ErrNoSuchEntity {
		return nil, ErrUserExists
	}

	user.Company = companyKey
	user.FirstName = firstName
	user.LastName = lastName
	user.Email = email
	user.SetPassword(password)
	user.Timezone = timezone
	if _, err := nds.Put(ctx, userKey, user); err != nil {
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
	if err := nds.Get(ctx, NewUserKey(ctx, company, email), &user); err != nil {
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
	return nds.Put(ctx, u.Key(ctx), u)
}

// FullName returns the User's full name.
func (u *User) FullName() string {
	return u.FirstName + " " + u.LastName
}

// ChannelKey is the User's unique Channel id.
func (u *User) ChannelKey() string {
	return fmt.Sprintf("%s-%s", u.Company.StringID(), u.Email)
}

// NewRecoveryTokenKey creates fully-qualified datastore keys for RecoveryTokens.
func NewRecoveryTokenKey(
	ctx context.Context,
	parent *datastore.Key, tokenID string,
) *datastore.Key {
	return datastore.NewKey(ctx, tokenKind, tokenID, 0, parent)
}

// CreateRecoveryToken stores and returns a new recovery token for the
// given company, user pair.
func CreateRecoveryToken(
	ctx context.Context,
	company, user *datastore.Key,
) (*datastore.Key, *RecoveryToken, error) {
	token := RecoveryToken{}
	token.Company = company
	token.User = user
	token.initTimes()
	tokenNonce := utils.UUID4()

	tokenKey := NewRecoveryTokenKey(ctx, company, tokenNonce)
	if _, err := nds.Put(ctx, tokenKey, &token); err != nil {
		return nil, nil, err
	}

	return tokenKey, &token, nil
}

// GetRecoveryToken returns a token belonging to a given Company by
// tokenID address.
func GetRecoveryToken(
	ctx context.Context,
	company *datastore.Key,
	tokenID string,
) (*RecoveryToken, error) {

	var token RecoveryToken
	if err := nds.Get(ctx, NewRecoveryTokenKey(ctx, company, tokenID), &token); err != nil {
		return nil, err
	}

	if time.Now().Sub(token.CreatedAt) >= tokenTTL {
		return nil, ErrTokenExpired
	}

	return &token, nil
}
