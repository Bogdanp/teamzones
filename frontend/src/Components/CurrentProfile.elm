module Components.CurrentProfile where

import Effects exposing (Effects)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Signal exposing (Address)

import Components.Form as FC exposing (form, submitWithOptions, textField)
import Components.Page exposing (page)
import Util exposing (pure)


type Message
  = Submit
  | ToForm Form.Action


type alias Profile
  = { name : String }


type alias Model
  = { form : Form () Profile
    , pending : Bool
    }


validate : Validation () Profile
validate =
  form1
    Profile
    (get "name" string)


init : Model
init =
  { form = Form.initial [] validate
  , pending = False
  }


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    Submit ->
      -- FIXME: implement submit
      pure model

    ToForm m ->
      pure { model | form = Form.update m model.form }


view : Address Message -> Model -> Html
view messages {form, pending} =
  let
    formMessages =
      Signal.forwardTo messages ToForm

    textField' label name =
      textField label name formMessages form
  in
    page
      "Your Profile"
      [ FC.form (Signal.message messages Submit)
          [ textField' "Name" "name"
          , submitWithOptions { label = "Update", disabled = pending }
          ]
      ]
