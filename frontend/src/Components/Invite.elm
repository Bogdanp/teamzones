module Components.Invite ( Model, Message(..)
                         , init, update, view
                         ) where

import Effects exposing (Effects)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Http.Extra as HttpExtra
import Json.Encode
import Signal exposing (Address)

import Api exposing (Errors, send', post)
import Components.Form as FC exposing (form, submitWithOptions, textField)
import Components.Page exposing (page)
import Util exposing ((=>), pure, on')


type Message
  = Submit
  | ToForm Form.Action
  | InviteResponse (Result (HttpExtra.Error Errors) (HttpExtra.Response String))


type alias Invite
  = { name : String
    , email : String
    }


type alias Model
  = { form : Form () Invite
    , pending : Bool
    }


validate : Validation () Invite
validate =
  form2
    Invite
    (get "name" string)
    (get "email" email)


init : Model
init =
  { form = Form.initial [] validate
  , pending = False
  }


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    Submit ->
      let
        form = Form.update Form.Submit model.form
        invite = Form.getOutput form
      in
        case invite of
          Nothing ->
            pure { model | form = form }

          Just invite ->
            ({ model | form = form, pending = True }, createInvite invite)

    ToForm m ->
      pure { model | form = Form.update m model.form }

    InviteResponse (Err error) ->
      -- FIXME: Display real errors
      pure { model | pending = False }

    InviteResponse (Ok _) ->
      pure { model | form = Form.initial [] validate, pending = False }


view : Address Message -> Model -> Html
view messages {form, pending} =
  let
    formMessages =
      Signal.forwardTo messages ToForm

    textField' label name =
      textField label name formMessages form
  in
    page
      "Invite Teammates"
      [ p [] [ text "You can use this form to invite members to your team." ]
      , FC.form (Signal.message messages Submit)
          [ textField' "Name" "name"
          , textField' "Email address" "email"
          , submitWithOptions { label = "Send invite", disabled = pending }
          ]
      ]


encodeInvite : Invite -> Json.Encode.Value
encodeInvite invite =
  Json.Encode.object
      [ "name" => Json.Encode.string invite.name
      , "email" => Json.Encode.string invite.email
      ]


createInvite : Invite -> Effects Message
createInvite invite =
  post "invites"
    |> send' InviteResponse (encodeInvite invite)
