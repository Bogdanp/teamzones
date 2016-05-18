module Components.Settings.Team exposing (Model, Msg, ParentMsg(..), init, update, view)

import Api exposing (Errors, deletePlain)
import Components.ConfirmationButton as CB
import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import HttpBuilder
import Types exposing (User, UserRole(..))


type ParentMsg
    = DeleteUser String


type Msg
    = ToDeleteButton String CB.Msg
    | DeleteError String (HttpBuilder.Error Errors)
    | DeleteSuccess String (HttpBuilder.Response String)


type alias Model =
    { currentUser : User
    , teamMembers : List User
    , deleteMemberButtons : Dict String CB.Model
    }


init : User -> List User -> Model
init user members =
    let
        deleteMemberButtons =
            List.map (\u -> ( u.email, CB.init "Delete" )) members
                |> Dict.fromList
    in
        { currentUser = user
        , teamMembers = members
        , deleteMemberButtons = deleteMemberButtons
        }


update : Msg -> Model -> ( Model, Cmd Msg, Maybe ParentMsg )
update msg ({ teamMembers, deleteMemberButtons } as model) =
    let
        updateButtons email msg =
            Dict.map
                (\e b ->
                    if e == email then
                        CB.update msg b
                    else
                        b
                )
                deleteMemberButtons
    in
        case msg of
            ToDeleteButton email ((CB.ToParent (CB.Confirm)) as msg) ->
                ( { model | deleteMemberButtons = updateButtons email msg }, deleteUser email, Nothing )

            ToDeleteButton email msg ->
                ( { model | deleteMemberButtons = updateButtons email msg }, Cmd.none, Nothing )

            DeleteError email erorr ->
                -- FIXME: Display errors
                ( model, Cmd.none, Nothing )

            DeleteSuccess email _ ->
                let
                    members =
                        List.filter ((/=) email << .email) teamMembers

                    buttons =
                        Dict.remove email deleteMemberButtons
                in
                    ( { model | teamMembers = members, deleteMemberButtons = buttons }, Cmd.none, Just (DeleteUser email) )


view : Model -> Html Msg
view { currentUser, teamMembers, deleteMemberButtons } =
    let
        members =
            List.sortBy (.role >> toString) teamMembers
    in
        div []
            [ br [] []
            , table [ class "sm-ml" ]
                [ thead []
                    [ tr []
                        [ td [] [ text "Name" ]
                        , td [] [ text "Email" ]
                        , td [] [ text "Role" ]
                        , td [] []
                        ]
                    ]
                , tbody [] (List.map (memberRow currentUser deleteMemberButtons) members)
                ]
            ]


memberRow : User -> Dict String CB.Model -> User -> Html Msg
memberRow currentUser buttons { name, email, role } =
    let
        deleteButton =
            case Dict.get email buttons of
                Just button ->
                    CB.view button
                        |> Html.map (ToDeleteButton email)

                Nothing ->
                    Debug.crash "impossible"
    in
        tr []
            [ td [] [ text name ]
            , td [] [ text email ]
            , td [] [ text (toString role) ]
            , td []
                [ if role /= Main && currentUser.email /= email then
                    deleteButton
                  else
                    text ""
                ]
            ]


deleteUser : String -> Cmd Msg
deleteUser email =
    deletePlain (DeleteError email) (DeleteSuccess email) ("/users/" ++ email)
