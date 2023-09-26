module Example.Contact where

import Example.Effects.Users (User (..), UserStore)
import Example.Effects.Users qualified as Users
import Web.Htmx
import Web.Hyperbole (view)
import Web.Hyperbole.Htmx
import Web.Scotty hiding (text)
import Web.UI

route :: UserStore -> ScottyM ()
route us = do
  get "/contact/:id" $ do
    u <- loadUser
    view $ viewContact u

  get "/contact/:id/edit" $ do
    u <- loadUser
    view $ editContact u

  post "/contact/:id/save" $ do
    u <- userFormData
    Users.save us u
    view $ viewContact u
 where
  loadUser :: ActionM User
  loadUser = do
    uid <- param "id"
    mu <- Users.load us uid
    maybe next pure mu

  userFormData :: ActionM User
  userFormData = do
    uid <- param "id"
    firstName <- param "firstName"
    lastName <- param "lastName"
    email <- param "email"
    pure $ User uid firstName lastName email True

viewContact :: User -> View ()
viewContact u = do
  row (hxTarget This . hxSwap OuterHTML) $ do
    col (pad 10 . gap 10) $ do
      el_ $ do
        label id "First Name:"
        text u.firstName

      el_ $ do
        label id "Last Name:"
        text u.lastName

      el_ $ do
        label id "Email"
        text u.email

      let uid = u.id :: Int
      button (hxGet ("contact" // segment uid // "edit")) "Click to Edit"
    space

editContact :: User -> View ()
editContact u = do
  row (hxTarget This . hxSwap OuterHTML) $ do
    form (hxPost ("contact" // segment u.id // "save") . pad 10 . gap 10) $ do
      label id $ do
        text "First Name"
        input (name "firstName" . value u.firstName)

      label id $ do
        text "Last Name"
        input (name "lastName" . value u.lastName)

      label id $ do
        text "Email"
        input (name "email" . value u.email)

      button id "Submit"

      -- no, we don't want it to re-render everything!
      -- yikes
      button (hxGet ("contact" // segment u.id)) "Cancel"
    space