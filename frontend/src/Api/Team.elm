module Api.Team exposing (deleteUser)

import Api exposing (Error, Response, deletePlain)
import Task exposing (Task)


deleteUser : String -> Task Error (Response String)
deleteUser email =
    deletePlain ("/users/" ++ email)
