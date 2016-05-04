module Components.Invite ( Model, Message(..)
                         , init, update, view
                         ) where

import Effects exposing (Effects)
import Form exposing (Form)
import Form.Input as Input
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (Address)

import Components.Form exposing (textField)
import Components.Page exposing (page)
import Util exposing (pure)


type Message
  = ToForm Form.Action


type alias Invite
  = { email : String }


type alias Model
  = { form : Form () Invite }


validate : Validation () Invite
validate =
  form1 Invite (get "email" email)


init : Model
init =
  { form = Form.initial [] validate }


update : Message -> Model -> (Model, Effects Message)
update message ({form} as model) =
  case message of
    ToForm m ->
      pure { model | form = Form.update m form }


view : Address Message -> Model -> Html
view messages {form} =
  let
    formMessages = Signal.forwardTo messages ToForm
  in
    page
      "Invite Teammates"
      [ div
          [ class "form-group" ]
          [ textField "Email Address" "email" formMessages form
          ]
      ]
