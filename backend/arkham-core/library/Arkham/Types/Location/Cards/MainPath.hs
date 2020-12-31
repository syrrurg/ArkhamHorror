{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Location.Cards.MainPath
  ( MainPath(..)
  , mainPath
  )
where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype MainPath = MainPath Attrs
  deriving newtype (Show, ToJSON, FromJSON)

mainPath :: MainPath
mainPath = MainPath $ baseAttrs
  "01149"
  (LocationName "Main Path" Nothing)
  EncounterSet.TheDevourerBelow
  2
  (Static 0)
  Squiggle
  [Square, Plus]
  [Woods]

instance HasModifiersFor env MainPath where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env MainPath where
  getActions iid NonFast (MainPath attrs@Attrs {..}) | locationRevealed =
    withBaseActions iid NonFast attrs $ do
      canAffordActions <- getCanAffordCost
        iid
        (toSource attrs)
        (Just Action.Resign)
        (ActionCost 1)
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility
              (toSource attrs)
              1
              (ActionAbility (Just Action.Resign) (ActionCost 1))
            )
        | iid `member` locationInvestigators && canAffordActions
        ]
  getActions i window (MainPath attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env MainPath where
  runMessage msg l@(MainPath attrs@Attrs {..}) = case msg of
    UseCardAbility iid source _ 1 | isSource attrs source && locationRevealed ->
      l <$ unshiftMessage (Resign iid)
    AddConnection lid _ | locationId /= lid -> do
      isWoods <- member Woods <$> getSet lid
      if isWoods
        then MainPath
          <$> runMessage msg (attrs & connectedLocations %~ insertSet lid)
        else MainPath <$> runMessage msg attrs
    _ -> MainPath <$> runMessage msg attrs
