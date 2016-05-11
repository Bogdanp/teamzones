module Components.Form ( FieldOptions, form
                       , submit, submitWithOptions
                       , button, buttonWithOptions

                       , InputOptions, defaultOptions
                       , textInput, plainTextInput
                       , selectInput, plainSelectInput
                       ) where

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
        [ Html.input [ type' "submit"
                     , value label
                     , disabled options.disabled
                     ] []
        ]
    ]


button : String -> Html
button label =
  buttonWithOptions { label = label, disabled = False }


buttonWithOptions : FieldOptions -> Html
buttonWithOptions ({label} as options) =
  div
    [ class "input-group" ]
    [ div [ class "spacer" ] []
    , div
        [ class "input" ]
        [ Html.input [ type' "button"
                     , value label
                     , disabled options.disabled
                     ] []
        ]
    ]


type alias InputOptions
  = { name : String
    , spacer : Bool
    , label : Maybe String
    , placeholder : Maybe String
    , disabled : Bool
    , classList : List (String, Bool)
    }


defaultOptions : String -> InputOptions
defaultOptions name =
  { name = name
  , spacer = False
  , label = Nothing
  , placeholder = Nothing
  , disabled = False
  , classList = []
  }


textInput : InputOptions -> Address Form.Action -> Form e a -> Html
textInput options = input options Input.textInput


plainTextInput : String -> Address Form.Action -> Form e a -> Html
plainTextInput name = textInput <| defaultOptions name


selectInput : InputOptions -> List (String, String) -> Address Form.Action -> Form e a -> Html
selectInput options = Input.selectInput >> input options


plainSelectInput : String -> List (String, String) -> Address Form.Action -> Form e a -> Html
plainSelectInput name values = selectInput (defaultOptions name) values


input : InputOptions -> Input e String -> Address Form.Action -> Form e a -> Html
input options inputFn messages form =
  let
    field =
      Form.getFieldAsString options.name form

    fieldId =
      "field-" ++ options.name

    (hasError, errorsHtml) =
      case field.liveError of
        Nothing ->
          (False, text "")

        Just error ->
          (True, span [ class "error" ] [ text <| toString error ])

    inputHtml =
      div
        [ class "input" ]
        [ inputFn field messages [ id fieldId
                                 , placeholder (Maybe.withDefault "" options.placeholder)
                                 , classList ([ "error" => hasError ] ++ options.classList)
                                 ]
        , errorsHtml
        ]
  in
    case (options.spacer, options.label) of
      (True, _) ->
        div
          [ class "input-group" ]
          [ div [ class "spacer" ] [ ]
          , inputHtml
          ]

      (False, Nothing) ->
        inputHtml

      (False, Just fieldLabel) ->
        div
          [ class "input-group" ]
          [ label [ for fieldId ] [ text fieldLabel ]
          , inputHtml
          ]
