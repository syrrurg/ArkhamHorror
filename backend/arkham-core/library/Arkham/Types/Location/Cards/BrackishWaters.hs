module Arkham.Types.Location.Cards.BrackishWaters
  ( BrackishWaters(..)
  , brackishWaters
  ) where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype BrackishWaters = BrackishWaters LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

brackishWaters :: BrackishWaters
brackishWaters = BrackishWaters $ baseAttrs
  "81010"
  (Name "Brackish Waters" Nothing)
  EncounterSet.CurseOfTheRougarou
  1
  (Static 0)
  Triangle
  [Squiggle, Square, Diamond, Hourglass]
  [Riverside, Bayou]

instance HasModifiersFor env BrackishWaters where
  getModifiersFor _ (InvestigatorTarget iid) (BrackishWaters attrs) =
    pure $ toModifiers
      attrs
      [ CannotPlay [AssetType] | iid `elem` locationInvestigators attrs ]
  getModifiersFor _ _ _ = pure []

-- TODO: Cost is an OR and we should be able to capture this
-- first idea is change discard to take a source @DiscardCost 1 [DiscardFromHand, DiscardFromPlay] (Just AssetType) mempty mempty@
instance ActionRunner env => HasActions env BrackishWaters where
  getActions iid NonFast (BrackishWaters attrs@LocationAttrs {..}) =
    withBaseActions iid NonFast attrs $ do
      assetNotTaken <- isNothing
        <$> getId @(Maybe StoryAssetId) (CardCode "81021")
      hand <- getHandOf iid
      inPlayAssetsCount <- getInPlayOf iid <&> count
        (\case
          PlayerCard pc -> pcCardType pc == AssetType
          EncounterCard _ -> False
        )
      let
        assetsCount =
          count
              (maybe False (playerCardMatch (AssetType, Nothing)) . toPlayerCard
              )
              hand
            + inPlayAssetsCount
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 1)
            )
        | (iid `member` locationInvestigators)
          && (assetsCount >= 2)
          && assetNotTaken
        ]
  getActions i window (BrackishWaters attrs) = getActions i window attrs

instance LocationRunner env => RunMessage env BrackishWaters where
  runMessage msg l@(BrackishWaters attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      assetIds <- getSetList @AssetId iid
      handAssetIds <- map unHandCardId <$> getSetList (iid, AssetType)
      l <$ unshiftMessages
        [ chooseN iid 2
        $ [ Discard (AssetTarget aid) | aid <- assetIds ]
        <> [ DiscardCard iid cid | cid <- handAssetIds ]
        , BeginSkillTest iid source (toTarget attrs) Nothing SkillAgility 3
        ]
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        fishingNet <- PlayerCard <$> genPlayerCard "81021"
        l <$ unshiftMessage (TakeControlOfSetAsideAsset iid fishingNet)
    _ -> BrackishWaters <$> runMessage msg attrs
