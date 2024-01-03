module Arkham.Asset.Cards.CatBurglar1 (CatBurglar1 (..), catBurglar1) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Helpers.Location
import Arkham.Matcher
import Arkham.Movement
import Arkham.Prelude

newtype CatBurglar1 = CatBurglar1 AssetAttrs
  deriving anyclass (IsAsset)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

catBurglar1 :: AssetCard CatBurglar1
catBurglar1 = ally CatBurglar1 Cards.catBurglar1 (2, 2)

instance HasModifiersFor CatBurglar1 where
  getModifiersFor (InvestigatorTarget iid) (CatBurglar1 a) = do
    pure $ toModifiers a [SkillModifier #agility 1 | controlledBy a iid]
  getModifiersFor _ _ = pure []

instance HasAbilities CatBurglar1 where
  getAbilities (CatBurglar1 a) =
    [ doesNotProvokeAttacksOfOpportunity
        $ controlledAbility a 1 (oneOf [exists EnemyEngagedWithYou, exists AccessibleLocation])
        $ actionAbilityWithCost (exhaust a)
    ]

instance RunMessage CatBurglar1 where
  runMessage msg (CatBurglar1 attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      engagedEnemyIds <- selectList $ enemyEngagedWith iid
      canDisengage <- iid <=~> InvestigatorCanDisengage
      accessibleLocationIds <- accessibleLocations iid
      player <- getPlayer iid
      pushAll
        $ [DisengageEnemy iid eid | canDisengage, eid <- engagedEnemyIds]
        <> [ chooseOne player $ targetLabels accessibleLocationIds (only . Move . move attrs iid)
           | notNull accessibleLocationIds
           ]
      pure $ CatBurglar1 $ attrs & exhaustedL .~ True
    _ -> CatBurglar1 <$> runMessage msg attrs
