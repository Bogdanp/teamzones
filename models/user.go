package models

import (
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/appengine/datastore"
)

const passwordCost = 10

type User struct {
	Email    string
	Password string

	Times
}

func NewUser() *User {
	user := User{}
	user.initTimes()
	return &user
}

func (u *User) SetPassword(password string) error {
	hashed, error := bcrypt.GenerateFromPassword([]byte(password), passwordCost)
	u.Password = string(hashed)
	return error
}

func (u *User) CheckPasssword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
}

func (u *User) Load(p []datastore.Property) error {
	return datastore.LoadStruct(u, p)
}

func (u *User) Save() ([]datastore.Property, error) {
	u.updateTimes()

	return datastore.SaveStruct(u)
}
