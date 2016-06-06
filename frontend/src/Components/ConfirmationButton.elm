module Components.ConfirmationButton exposing (Model, Msg(ToParent), ParentMsg(..), init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Model =
    { confirming : Bool
    , label : String
    }


type ParentMsg
    = Confirm
    | Cancel


type Msg
    = Click
    | ToParent ParentMsg


init : String -> Model
init label =
    { confirming = False, label = label }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Click ->
            { model | confirming = True }

        ToParent msg ->
            { model | confirming = False }


view : Model -> Html Msg
view { confirming, label } =
    let
        button msg label =
            input
                [ class "button button--padded"
                , type' "button"
                , value label
                , onClick msg
                ]
                []
    in
        if confirming then
            div [ class "confirmation-button" ]
                [ button (ToParent Confirm) "Confirm"
                , button (ToParent Cancel) "Cancel"
                ]
        else
            button Click label
