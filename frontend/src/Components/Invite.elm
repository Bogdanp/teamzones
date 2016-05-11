module Components.Invite
    exposing
        ( Model
        , Message(..)
        , init
        , update
        , view
        )

import Api exposing (Errors, postPlain)
import Components.Form as FC exposing (form, submitWithOptions)
import Components.Page exposing (page)
import Form exposing (Form)
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.App as Html
import HttpBuilder
import Json.Encode
import Util exposing ((=>), pure, on')


type Message
    = Submit
    | ToForm Form.Msg
    | InviteError (HttpBuilder.Error Errors)
    | InviteSuccess (HttpBuilder.Response String)


type alias Invite =
    { name : String
    , email : String
    }


type alias Model =
    { form : Form () Invite
    , pending : Bool
    }


validate : Validation () Invite
validate =
    form2 Invite
        (get "name" string)
        (get "email" email)


init : Model
init =
    { form = Form.initial [] validate
    , pending = False
    }


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        Submit ->
            let
                form =
                    Form.update Form.Submit model.form

                invite =
                    Form.getOutput form
            in
                case invite of
                    Nothing ->
                        pure { model | form = form }

                    Just invite ->
                        ( { model | form = form, pending = True }, createInvite invite )

        ToForm m ->
            pure { model | form = Form.update m model.form }

        InviteError error ->
            -- FIXME: Display real errors
            pure { model | pending = False }

        InviteSuccess _ ->
            pure { model | form = Form.initial [] validate, pending = False }


view : Model -> Html Message
view { form, pending } =
    let
        textField' label name =
            let
                options =
                    FC.defaultOptions name
            in
                Html.map ToForm (FC.textInput { options | label = Just label } form)
    in
        page "Invite Teammates"
            [ p [] [ text "You can use this form to invite members to your team." ]
            , FC.form Submit
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


createInvite : Invite -> Cmd Message
createInvite invite =
    postPlain InviteError InviteSuccess (encodeInvite invite) "invites"
