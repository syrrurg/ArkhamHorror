module Arkham.Treachery.Cards.ChaosInTheWater
  ( chaosInTheWater
  , ChaosInTheWater(..)
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Assets
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Treachery.Attrs
import Arkham.Treachery.Cards qualified as Cards

newtype ChaosInTheWater = ChaosInTheWater TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor m, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chaosInTheWater :: TreacheryCard ChaosInTheWater
chaosInTheWater = treachery ChaosInTheWater Cards.chaosInTheWater

instance RunMessage ChaosInTheWater where
  runMessage msg t@(ChaosInTheWater attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      innocentRevelerIds <- selectList
        (AssetControlledBy You <> assetIs Assets.innocentReveler)
      investigatorsWithRevelers <-
        catMaybes
          <$> traverse
                (selectOne . HasMatchingAsset . AssetWithId)
                innocentRevelerIds
      t <$ pushAll
        [ RevelationSkillTest iid' source SkillAgility 4
        | iid' <- nub (iid : investigatorsWithRevelers)
        ]
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        push $ InvestigatorAssignDamage
          iid
          source
          (DamageFirst Assets.innocentReveler)
          1
          0
        pure t
    _ -> ChaosInTheWater <$> runMessage msg attrs
