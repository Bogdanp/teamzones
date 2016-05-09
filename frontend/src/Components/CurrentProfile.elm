module Components.CurrentProfile where

import Effects exposing (Effects)
import Form exposing (Form)
import Form.Field exposing (Field(..))
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http.Extra as HttpExtra
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Signal exposing (Address)

import Api exposing (Errors, send)
import Components.Form as FC exposing (form, submitWithOptions, textField)
import Components.Page exposing (page)
import Types exposing (User)
import Util exposing (pure)


type Message
  = Submit
  | ToForm Form.Action
  | UploadUriResponse (Result (HttpExtra.Error Errors) (HttpExtra.Response String))


type alias Profile
  = { name : String }


type alias Model
  = { form : Form () Profile
    , pending : Bool
    , uploadUri : Maybe String
    }


validate : Validation () Profile
validate =
  form1
    Profile
    (get "name" string)


init : User -> (Model, Effects Message)
init user =
  ( { form = Form.initial [ ("name", Text user.name) ] validate
    , pending = False
    , uploadUri = Nothing
    }
  , createUploadUri
  )


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    Submit ->
      -- FIXME: implement submit
      pure model

    ToForm m ->
      pure { model | form = Form.update m model.form }

    UploadUriResponse (Err error) ->
      (model, createUploadUri)

    UploadUriResponse (Ok response) ->
      pure { model | uploadUri = Just response.data }


view : Address Message -> Model -> Html
view messages {form, pending, uploadUri} =
  let
    formMessages =
      Signal.forwardTo messages ToForm

    textField' label name =
      textField label name formMessages form

    uploadPending =
      Maybe.map (always False) uploadUri
        |> Maybe.withDefault True
  in
    page
      "Your Profile"
      [ Html.form
          [ action (Maybe.withDefault "" uploadUri)
          , class "form-group no-pt"
          , method "POST"
          , enctype "multipart/form-data"
          ]
          [ div
              [ class "input-group" ]
              [ label
                  [ for "avatar-file" ]
                  [ text "Profile Picture" ]
              , div
                  [ class "input" ]
                  [ input [ type' "file"
                          , id "avatar-file"
                          , name "avatar-file"
                          , accept "image/*"
                          ] []
                  ]
              ]
          , div
              [ class "input-group" ]
              [ div [ class "spacer" ] []
              , div
                  [ class "input" ]
                  [ input [ type' "submit"
                          , value "Upload"
                          , disabled uploadPending
                          ] []
                  , input [ type' "button"
                          , value "Delete Profile Picture"
                          ] []
                  ]
              ]
          ]
      , FC.form (Signal.message messages Submit)
          [ textField' "Name" "name"
          , submitWithOptions { label = "Update", disabled = pending }
          ]
      ]


createUploadUri : Effects Message
createUploadUri =
  Api.get "upload"
    |> send UploadUriResponse Json.Encode.null ("uri" := Json.string)
