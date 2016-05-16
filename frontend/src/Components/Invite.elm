module Components.Invite
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api exposing (Errors, postPlain, postJson)
import Components.Form as FC exposing (form, submitWithOptions)
import Components.Page exposing (page)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import HttpBuilder
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Util exposing ((=>), on')


type Msg
    = Submit
    | CreateBulkInvite
    | ToForm Form.Msg
    | InviteError (HttpBuilder.Error Errors)
    | InviteSuccess (HttpBuilder.Response String)
    | BulkInviteError (HttpBuilder.Error Errors)
    | BulkInviteSuccess (HttpBuilder.Response BulkInvite)


type alias Invite =
    { name : String
    , email : String
    }


type alias BulkInvite =
    { uri : String }


type alias Model =
    { form : Form () Invite
    , pending : Bool
    , bulkInvite : Maybe BulkInvite
    }


validate : Validation () Invite
validate =
    form2 Invite
        (get "name" (string `andThen` minLength 3 `andThen` maxLength 50))
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
                        { model | form = form, pending = True } ! [ createInvite invite ]

        CreateBulkInvite ->
            model ! [ createBulkInvite ]

        ToForm m ->
            { model | form = Form.update m model.form } ! []

        InviteError error ->
            -- FIXME: Display real errors
            { model | pending = False } ! []

        InviteSuccess _ ->
            { model | form = Form.initial [] validate, pending = False } ! []

        BulkInviteError error ->
            -- FIXME: Display real errors
            { model | pending = False } ! []

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
                [ textInput' "Name" "name"
                , textInput' "Email address" "email"
                , submitWithOptions { label = "Send invite", disabled = pending }
                ]
            , p [] [ text "Want to invite team members in bulk?" ]
            , div [ class "input-group" ]
                [ div [ class "input" ]
                    [ input
                        [ type' "button"
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

                Just { uri } ->
                    div []
                        [ p []
                            [ text "Share this URL with your teammates so they can join your team without an e-mail invitation: "
                            , br [] []
                            , br [] []
                            , a [ href uri ]
                                [ text uri ]
                            , br [] []
                            , br [] []
                            , text " This URL will expire in 2 hours."
                            ]
                        ]
            ]


encodeInvite : Invite -> Json.Encode.Value
encodeInvite invite =
    Json.Encode.object
        [ "name" => Json.Encode.string invite.name
        , "email" => Json.Encode.string invite.email
        ]


createInvite : Invite -> Cmd Msg
createInvite invite =
    postPlain InviteError InviteSuccess (encodeInvite invite) "invites"


decodeBulkInvite : Json.Decoder BulkInvite
decodeBulkInvite =
    Json.object1 BulkInvite
        ("uri" := Json.string)


createBulkInvite : Cmd Msg
createBulkInvite =
    postJson BulkInviteError BulkInviteSuccess Json.Encode.null decodeBulkInvite "bulk-invites"
