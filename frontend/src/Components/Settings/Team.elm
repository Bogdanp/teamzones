module Components.Settings.Team exposing (Model, Msg, init, update, view)

import Api exposing (Errors, deletePlain)
import Components.ConfirmationButton as CB
import Dict exposing (Dict)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import HttpBuilder
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..))
import Types exposing (AnchorTo, User, UserRole(..))
import Util exposing ((=>), on')


type alias Context pmsg =
    { deleteUser : String -> pmsg
    , currentUser : User
    , teamMembers : List User
    }


type Msg
    = RouteTo Sitemap
    | ToDeleteButton String CB.Msg
    | DeleteError String (HttpBuilder.Error Errors)
    | DeleteSuccess String (HttpBuilder.Response String)


type alias Model pmsg =
    { rootDeleteUser : String -> pmsg
    , currentUser : User
    , teamMembers : List User
    , deleteMemberButtons : Dict String CB.Model
    }


init : Context pmsg -> Model pmsg
init { deleteUser, currentUser, teamMembers } =
    let
        deleteMemberButtons =
            List.map (\u -> ( u.email, CB.init "Delete" )) teamMembers
                |> Dict.fromList
    in
        { rootDeleteUser = deleteUser
        , currentUser = currentUser
        , teamMembers = teamMembers
        , deleteMemberButtons = deleteMemberButtons
        }


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ rootDeleteUser, teamMembers, deleteMemberButtons } as model) =
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
            RouteTo route ->
                ( model, pushPath (Routes.route route), Nothing )

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
                    ( { model | teamMembers = members, deleteMemberButtons = buttons }, Cmd.none, Just (rootDeleteUser email) )


view : Model pmsg -> Html Msg
view { currentUser, teamMembers, deleteMemberButtons } =
    let
        members =
            List.sortBy (.role >> toString) teamMembers
    in
        div []
            [ br [] []
            , table []
                [ thead []
                    [ tr []
                        [ td [ style [ "width" => "30%" ] ] [ text "Name" ]
                        , td [ style [ "width" => "30%" ] ] [ text "Email" ]
                        , td [ style [ "width" => "20%" ] ] [ text "Role" ]
                        , td [ style [ "width" => "20%" ] ] []
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
            [ td [] [ anchorTo (ProfileR email) [] [ text name ] ]
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


anchorTo : AnchorTo Msg
anchorTo route attrs =
    a ([ on' "click" (RouteTo route), href (Routes.route route) ] ++ attrs)
