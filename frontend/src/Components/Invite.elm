module Components.Invite
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api exposing (Error, Response)
import Api.Invite as InviteApi exposing (Invite, BulkInvite, createInvite, createBulkInvite)
import Components.Form as FC exposing (form, submitWithOptions)
import Components.Notifications exposing (apiError)
import Components.Page exposing (page)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Task
import Util exposing ((=>), on', ttl)


type Msg
    = Submit
    | CreateBulkInvite
    | ToForm Form.Msg
    | InviteError Error
    | InviteSuccess (Response String)
    | BulkInviteError Error
    | BulkInviteSuccess (Response BulkInvite)


type alias Model =
    { form : Form () Invite
    , pending : Bool
    , bulkInvite : Maybe BulkInvite
    }


validate : Validation () Invite
validate =
    form3 Invite
        (get "first-name" (string `andThen` minLength 3 `andThen` maxLength 50))
        (get "last-name" (string `andThen` minLength 3 `andThen` maxLength 50))
        (get "email" email)


init : Model
init =
    { form = Form.initial [] validate
    , pending = False
    , bulkInvite = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Submit ->
            let
                form =
                    Form.update Form.Submit model.form

                invite =
                    Form.getOutput form
            in
                case invite of
                    Nothing ->
                        { model | form = form } ! []

                    Just invite ->
                        { model | form = form, pending = True }
                            ! [ createInvite invite
                                    |> Task.perform InviteError InviteSuccess
                              ]

        CreateBulkInvite ->
            model ! [ Task.perform BulkInviteError BulkInviteSuccess createBulkInvite ]

        ToForm m ->
            { model | form = Form.update m model.form } ! []

        InviteError error ->
            { model | pending = False } ! apiError error

        InviteSuccess _ ->
            { model | form = Form.initial [] validate, pending = False } ! []

        BulkInviteError error ->
            { model | pending = False } ! apiError error

        BulkInviteSuccess response ->
            { model | bulkInvite = Just response.data, pending = False } ! []


view : Model -> Html Msg
view { form, pending, bulkInvite } =
    let
        textInput' label name =
            let
                options =
                    FC.defaultOptions name
            in
                Html.map ToForm (FC.textInput { options | label = Just label } form)
    in
        page "Invite Teammates"
            [ p [] [ text "You can use this form to invite members to your team." ]
            , FC.form Submit
                [ textInput' "First name" "first-name"
                , textInput' "Last name" "last-name"
                , textInput' "Email address" "email"
                , submitWithOptions { label = "Send invite", disabled = pending }
                ]
            , p [] [ text "Want to invite team members in bulk?" ]
            , div [ class "input-group" ]
                [ div [ class "input-group__input" ]
                    [ input
                        [ class "button button--padded"
                        , type' "button"
                        , value "Generate bulk invite URL"
                        , disabled pending
                        , onClick CreateBulkInvite
                        ]
                        []
                    ]
                ]
            , case bulkInvite of
                Nothing ->
                    text ""

                Just ({ uri } as bulkInvite) ->
                    div []
                        [ p []
                            [ text "Share this URL with your teammates so they can join your team without an e-mail invitation:"
                            , br [] []
                            , br [] []
                            , a [ href uri ]
                                [ text uri ]
                            , br [] []
                            , br [] []
                            , text ("This URL will expire in " ++ ttl bulkInvite.ttl ++ ".")
                            ]
                        ]
            ]
