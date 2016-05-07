module Components.Form ( FieldOptions, form, submit, submitWithOptions, textField ) where

import Form exposing (Form)
import Form.Input as Input exposing (Input)
import Html exposing (..)
import Html.Attributes exposing (..)
import Signal exposing (Address, Message)

import Util exposing ((=>), on')


type alias FieldOptions
  = { label : String
    , disabled : Bool
    }


form : Message -> List Html -> Html
form message =
  Html.form
    [ class "form-group no-pt"
    , action ""
    , on' "submit" message
    ]


submit : String -> Html
submit label =
  submitWithOptions { label = label, disabled = False }


submitWithOptions : FieldOptions -> Html
submitWithOptions ({label} as options) =
  div
    [ class "input-group" ]
    [ div [ class "spacer" ] []
    , div
        [ class "input" ]
        [ input [ type' "submit"
                , value label
                , disabled options.disabled
                ] []
        ]
    ]



textField : String -> String -> Address Form.Action -> Form e a -> Html
textField = field Input.textInput


field : Input e String -> String -> String -> Address Form.Action -> Form e a -> Html
field inputFn fieldLabel fieldName messages form =
  let
    fieldId =
      "field-" ++ fieldName

    field' =
      Form.getFieldAsString fieldName form

    hasError =
      Maybe.map (always True) field'.liveError
        |> Maybe.withDefault False

    errors =
      case field'.liveError of
        Nothing ->
          text ""

        Just error ->
          span [ class "error" ] [ text <| toString error ]
  in
    div
      [ class "input-group" ]
      [ label [ for fieldId ] [ text fieldLabel ]
      , div
          [ class "input" ]
          [ inputFn field' messages [ id fieldId
                                    , placeholder fieldLabel
                                    , classList [ "error" => hasError ]
                                    ]
          , errors
          ]
      ]
