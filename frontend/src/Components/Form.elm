module Components.Form
    exposing
        ( ButtonOptions
        , form
        , submit
        , submitWithOptions
        , InputOptions
        , defaultOptions
        , textInput
        , plainTextInput
        , selectInput
        , plainSelectInput
        )

import Form exposing (Form)
import Form.Error exposing (Error(..))
import Form.Input as Input exposing (Input)
import Html exposing (..)
import Html.Attributes exposing (..)
import Util exposing ((=>), (?>), on')


type alias ButtonOptions =
    { label : String
    , disabled : Bool
    }


form : msg -> List (Html msg) -> Html msg
form msg =
    Html.form
        [ class "form-group no-pt"
        , action ""
        , on' "submit" msg
        ]


submit : String -> Html msg
submit label =
    submitWithOptions { label = label, disabled = False }


submitWithOptions : ButtonOptions -> Html msg
submitWithOptions ({ label } as options) =
    div [ class "input-group" ]
        [ div [ class "spacer" ] []
        , div [ class "input" ]
            [ Html.input
                [ type' "submit"
                , value label
                , disabled options.disabled
                ]
                []
            ]
        ]


type alias InputOptions =
    { name : String
    , spacer : Bool
    , label : Maybe String
    , placeholder : Maybe String
    , disabled : Bool
    , classList : List ( String, Bool )
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


textInput : InputOptions -> Form e a -> Html Form.Msg
textInput options =
    input options Input.textInput


plainTextInput : String -> Form e a -> Html Form.Msg
plainTextInput name =
    textInput <| defaultOptions name


selectInput : InputOptions -> List ( String, String ) -> Form e a -> Html Form.Msg
selectInput options =
    Input.selectInput >> input options


plainSelectInput : String -> List ( String, String ) -> Form e a -> Html Form.Msg
plainSelectInput name values =
    selectInput (defaultOptions name) values


input : InputOptions -> Input e String -> Form e a -> Html Form.Msg
input options inputFn form =
    let
        field =
            Form.getFieldAsString options.name form

        fieldId =
            "field-" ++ options.name

        ( hasError, errorsHtml ) =
            case field.liveError of
                Nothing ->
                    ( False, text "" )

                Just error ->
                    ( True, span [ class "error" ] [ text <| translateError error ] )

        inputHtml =
            div [ class "input" ]
                [ inputFn field
                    [ id fieldId
                    , placeholder (options.placeholder ?> "")
                    , classList ([ "error" => hasError ] ++ options.classList)
                    ]
                , errorsHtml
                ]
    in
        case ( options.spacer, options.label ) of
            ( True, _ ) ->
                div [ class "input-group" ]
                    [ div [ class "spacer" ] []
                    , inputHtml
                    ]

            ( False, Nothing ) ->
                inputHtml

            ( False, Just fieldLabel ) ->
                div [ class "input-group" ]
                    [ label [ for fieldId ] [ text fieldLabel ]
                    , inputHtml
                    ]


translateError : Error a -> String
translateError e =
    case e of
        Empty ->
            "This field is required."

        InvalidString ->
            "This field is required."

        InvalidEmail ->
            "Please enter a valid email address."

        ShorterStringThan n ->
            "This field must contain at least " ++ toString n ++ " characters."

        LongerStringThan n ->
            "This field can contain at most " ++ toString n ++ " characters."

        e ->
            toString e
