module Components.Invite ( Model, Message(..)
                         , init, update, view
                         ) where

import Effects exposing (Effects)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Signal exposing (Address)

import Components.Form as FC exposing (form, submit, textField)
import Components.Page exposing (page)
import Util exposing (pure, on')


type Message
  = Submit
  | ToForm Form.Action


type alias Invite
  = { name : String
    , email : String
    }


type alias Model
  = { form : Form () Invite }


validate : Validation () Invite
validate =
  form2
    Invite
    (get "name" string)
    (get "email" email)


init : Model
init =
  { form = Form.initial [] validate }


update : Message -> Model -> (Model, Effects Message)
update message ({form} as model) =
  case message of
    Submit ->
      -- FIXME: Handle submissions
      pure { model | form = Form.update Form.Submit form }

    ToForm m ->
      pure { model | form = Form.update m form }


view : Address Message -> Model -> Html
view messages {form} =
  let
    formMessages = Signal.forwardTo messages ToForm
  in
    page
      "Invite Teammates"
      [ p [] [ text "You can use this form to invite members to your team." ]
      , FC.form (Signal.message messages Submit)
          [ textField "Name" "name" formMessages form
          , textField "Email address" "email" formMessages form
          , submit "Send invite"
          ]
      ]
