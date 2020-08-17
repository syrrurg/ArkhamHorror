{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.CoverUp where

import Arkham.Json
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.FastWindow
import Arkham.Types.Helpers
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.TreacheryId
import ClassyPrelude
import Lens.Micro
import Safe (fromJustNote)

newtype CoverUpMetadata = CoverUpMetadata { coverUpClues :: Int }
  deriving stock (Show, Generic)

instance ToJSON CoverUpMetadata where
  toJSON = genericToJSON $ aesonOptions $ Just "coverUp"
  toEncoding = genericToEncoding $ aesonOptions $ Just "coverUp"

instance FromJSON CoverUpMetadata where
  parseJSON = genericParseJSON $ aesonOptions $ Just "coverUp"

newtype CoverUp = CoverUp (Attrs `With` CoverUpMetadata)
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

coverUp :: TreacheryId -> CoverUp
coverUp uuid =
  CoverUp
    $ ((weaknessAttrs uuid "01007")
        { treacheryAbilities =
          [ mkAbility
              (TreacherySource uuid)
              1
              (ReactionAbility (WhenDiscoverClues You YourLocation))
          ]
        }
      )
    `With` CoverUpMetadata 3

instance (TreacheryRunner env) => RunMessage env CoverUp where
  runMessage msg t@(CoverUp (attrs@Attrs {..} `With` metadata@CoverUpMetadata {..}))
    = case msg of
      Revelation iid tid | tid == treacheryId -> do
        unshiftMessages
          [ RemoveCardFromHand iid "01007"
          , AttachTreacheryToInvestigator tid iid
          ]
        CoverUp . (`with` metadata) <$> runMessage
          msg
          (attrs & attachedInvestigator ?~ iid)
      EndOfGame | coverUpClues > 0 ->
        let
          investigator =
            fromJustNote "missing investigator" treacheryAttachedInvestigator
        in t <$ unshiftMessage (SufferTrauma investigator 0 1)
      UseCardAbility iid _ (TreacherySource tid) 1 | tid == treacheryId -> do
        cluesToRemove <- withQueue $ \queue -> do
          let
            (before, after) = flip break queue $ \case
              DiscoverClues{} -> True
              _ -> False
            (DiscoverClues _ _ m) = case after of
              [] -> error "DiscoverClues has to be present"
              (x : _) -> x
            remaining = case after of
              [] -> []
              (_ : xs) -> xs
          (before <> remaining, m)
        let remainingClues = max 0 (coverUpClues - cluesToRemove)
        if remainingClues == 0
          then do
            unshiftMessage
              (RemoveAllModifiersOnTargetFrom
                (InvestigatorTarget iid)
                (TreacherySource treacheryId)
              )
            pure
              $ CoverUp
              $ (attrs & abilities .~ [])
              `with` CoverUpMetadata remainingClues
          else pure $ CoverUp (attrs `with` CoverUpMetadata remainingClues)
      _ -> CoverUp . (`with` metadata) <$> runMessage msg attrs
