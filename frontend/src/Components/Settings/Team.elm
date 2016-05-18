module Components.Settings.Team exposing (Model, Msg, init, update, view)

import Components.ConfirmationButton as CB
import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Types exposing (User, UserRole(..))


type Msg
    = Submit
    | ToDeleteButton String CB.Msg


type alias Model =
    { teamMembers : List User
    , deleteMemberButtons : Dict String CB.Model
    }


init : List User -> Model
init members =
    let
        deleteMemberButtons =
            List.map (\u -> ( u.email, CB.init "Delete" )) members
                |> Dict.fromList
    in
        { teamMembers = members
        , deleteMemberButtons = deleteMemberButtons
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ deleteMemberButtons } as model) =
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
            Submit ->
                model ! []

            ToDeleteButton email ((CB.ToParent (CB.Confirm)) as msg) ->
                -- FIXME: Delete members
                { model | deleteMemberButtons = updateButtons email msg } ! []

            ToDeleteButton email msg ->
                { model | deleteMemberButtons = updateButtons email msg } ! []


view : Model -> Html Msg
view { teamMembers, deleteMemberButtons } =
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
                , tbody [] (List.map (memberRow deleteMemberButtons) members)
                ]
            ]


memberRow : Dict String CB.Model -> User -> Html Msg
memberRow buttons { name, email, role } =
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
                [ if role /= Main then
                    deleteButton
                  else
                    text ""
                ]
            ]
