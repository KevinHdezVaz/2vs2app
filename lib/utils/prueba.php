<?php
namespace App\Jobs;

use App\Models\User;
use App\Models\MealPlan;
use Illuminate\Bus\Queueable;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Jobs\EnrichPlanWithPricesJob;
use App\Jobs\GenerateRecipeImagesJob;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;

class GenerateUserPlanJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $userId;
    public $timeout = 400;
    public $tries = 2;

    public function __construct($userId)
    {
        $this->userId = $userId;
    }

   public function handle()
    {
        Log::info('Iniciando GenerateUserPlanJob PERSONALIZADO', ['userId' => $this->userId]);
        
        $user = User::with('profile')->find($this->userId);
        if (!$user || !$user->profile) {
            Log::error('Usuario o perfil no encontrado.', ['userId' => $this->userId]);
            return;
        }
    
        $userName = $user->name;
        Log::info('Nombre del usuario obtenido', ['userId' => $this->userId, 'name' => $userName]);
    
        try {
            // PASO 1: Calcular macros siguiendo la metodología del PDF
            Log::info('Paso 1: Calculando TMB, GET y macros objetivo con perfil completo.', ['userId' => $user->id]);
            $nutritionalData = $this->calculateCompleteNutritionalPlan($user->profile, $userName);
            
            $personalizationData = $this->extractPersonalizationData($user->profile, $userName);

            // PASO 2: Generar plan con validación obligatoria
            Log::info('Paso 2: Generando plan nutricional ULTRA-PERSONALIZADO con validación.', ['userId' => $user->id]);
            $planData = $this->generateAndValidatePlan($user->profile, $nutritionalData, $userName);
            
            // PASO 3: Generar recetas si tiene suscripción activa
            if ($this->userHasActiveSubscription($user)) {
                Log::info('Paso 3: Generando recetas ultra-específicas - Usuario con suscripción activa.', ['userId' => $user->id]);
                $planWithRecipes = $this->generatePersonalizedRecipes($planData, $user->profile, $nutritionalData);
            } else {
                Log::info('Paso 3: Omitiendo generación de recetas - Usuario en periodo de prueba.', ['userId' => $user->id]);
                $planWithRecipes = $this->addTrialMessage($planData, $userName);
            }

            // PASO 4: Guardado del plan completo con datos de validación
            Log::info('Almacenando plan ultra-personalizado en la base de datos.', ['userId' => $user->id]);
            MealPlan::where('user_id', $user->id)->update(['is_active' => false]);
            
            $mealPlan = MealPlan::create([
                'user_id' => $user->id,
                'plan_data' => $planWithRecipes,
                'nutritional_data' => $nutritionalData,
                'personalization_data' => $personalizationData,
                'validation_data' => $planWithRecipes['validation_data'] ?? null,
                'generation_method' => $planWithRecipes['generation_method'] ?? 'ai',
                'is_active' => true,
            ]);

            // PASO 5: Despachar jobs de enriquecimiento
            Log::info('Despachando jobs de enriquecimiento.', ['mealPlanId' => $mealPlan->id]);
            EnrichPlanWithPricesJob::dispatch($mealPlan->id);

            Log::info('Plan ULTRA-PERSONALIZADO generado exitosamente.', ['userId' => $user->id, 'mealPlanId' => $mealPlan->id]);
            
        } catch (\Exception $e) {
            Log::error('Excepción crítica en GenerateUserPlanJob', [
                'userId' => $this->userId, 
                'exception' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }


    private function generateAndValidatePlan($profile, $nutritionalData, $userName): array
    {
        $maxAttempts = 3;
        $attempt = 0;
        
        while ($attempt < $maxAttempts) {
            $attempt++;
            Log::info("Intento #{$attempt} de generar plan válido", ['userId' => $profile->user_id]);
            
            // Generar plan con IA
            $planData = $this->generateUltraPersonalizedNutritionalPlan($profile, $nutritionalData, $userName, $attempt);
            
            if ($planData === null) {
                Log::warning("La IA no generó un plan válido en intento #{$attempt}", ['userId' => $profile->user_id]);
                continue;
            }
            
            // Validar el plan generado
            $validation = $this->validateGeneratedPlan($planData, $nutritionalData);
            
            if ($validation['is_valid']) {
                Log::info('Plan válido generado exitosamente', [
                    'userId' => $profile->user_id,
                    'attempt' => $attempt,
                    'total_macros' => $validation['total_macros']
                ]);
                
                $planData['validation_data'] = $validation;
                $planData['generation_method'] = 'ai_validated';
                return $planData;
            }
            
            Log::warning("Plan inválido en intento #{$attempt}", [
                'userId' => $profile->user_id,
                'errors' => $validation['errors']
            ]);
        }
        
        // Si todos los intentos fallan, usar plan determinístico
        Log::info('Usando plan determinístico después de fallar validación', ['userId' => $profile->user_id]);
        return $this->generateDeterministicPlan($nutritionalData, $profile, $userName);
    }


private function validateGeneratedPlan($planData, $nutritionalData): array
{
    $errors = [];
    $warnings = [];
    $totalMacros = ['protein' => 0, 'carbs' => 0, 'fats' => 0, 'calories' => 0];
    $foodAppearances = [];
    
    if (!isset($planData['nutritionPlan']['meals'])) {
        return [
            'is_valid' => false,
            'errors' => ['Estructura del plan inválida'],
            'warnings' => [],
            'total_macros' => $totalMacros
        ];
    }
    
    $budget = strtolower($nutritionalData['basic_data']['preferences']['budget'] ?? '');
    $isLowBudget = str_contains($budget, 'bajo');
    
    // Analizar cada comida
    foreach ($planData['nutritionPlan']['meals'] as $mealName => $mealData) {
        foreach ($mealData as $category => $categoryData) {
            if (!isset($categoryData['options']) || !is_array($categoryData['options'])) {
                continue;
            }
            
            // Tomar la primera opción de cada categoría para el cálculo
            $firstOption = $categoryData['options'][0] ?? null;
            if ($firstOption) {
                $totalMacros['protein'] += $firstOption['protein'] ?? 0;
                $totalMacros['carbs'] += $firstOption['carbohydrates'] ?? 0;
                $totalMacros['fats'] += $firstOption['fats'] ?? 0;
                $totalMacros['calories'] += $firstOption['calories'] ?? 0;
                
                // Registrar apariciones de alimentos
                foreach ($categoryData['options'] as $option) {
                    $foodName = strtolower($option['name'] ?? '');
                    if (!isset($foodAppearances[$foodName])) {
                        $foodAppearances[$foodName] = [];
                    }
                    $foodAppearances[$foodName][] = $mealName;
                    
                    // Validar presupuesto
                    if ($isLowBudget) {
                        if ($this->isFoodHighBudget($foodName)) {
                            $errors[] = "Alimento de presupuesto alto en plan bajo: {$option['name']} en {$mealName}";
                        }
                    } else {
                        if ($this->isFoodLowBudget($foodName)) {
                            $warnings[] = "Alimento de presupuesto bajo en plan alto: {$option['name']} en {$mealName}";
                        }
                    }
                }
            }
        }
    }
    
    // NUEVO: Validar que no haya huevos en múltiples comidas
    $mealsWithEggs = [];
    foreach ($planData['nutritionPlan']['meals'] as $mealName => $mealData) {
        $hasEggInMeal = false;
        
        foreach ($mealData as $category => $categoryData) {
            if (!isset($categoryData['options']) || !is_array($categoryData['options'])) {
                continue;
            }
            
            // Verificar cada opción en la categoría
            foreach ($categoryData['options'] as $option) {
                if ($this->isEggProduct($option['name'] ?? '')) {
                    $hasEggInMeal = true;
                    break;
                }
            }
            
            if ($hasEggInMeal) {
                $mealsWithEggs[] = $mealName;
                break; // No necesitamos seguir revisando esta comida
            }
        }
    }
    
    // Si hay huevos en más de una comida, es un error
    if (count($mealsWithEggs) > 1) {
        $errors[] = 'Huevos aparecen en múltiples comidas (máximo 1 vez al día): ' . implode(', ', $mealsWithEggs);
    }
    
    // Validar variedad adicional (huevos máximo 1 vez) - método antiguo por compatibilidad
    foreach (['huevo entero', 'huevos', 'claras de huevo'] as $eggType) {
        if (isset($foodAppearances[$eggType]) && count($foodAppearances[$eggType]) > 1) {
            $errors[] = "Huevos aparecen en múltiples comidas: " . implode(', ', $foodAppearances[$eggType]);
        }
    }
    
    // Validar macros totales (tolerancia 5%)
    $targetMacros = $nutritionalData['macros'];
    $tolerance = 0.05;
    
    $proteinDiff = abs($totalMacros['protein'] - $targetMacros['protein']['grams']);
    $carbsDiff = abs($totalMacros['carbs'] - $targetMacros['carbohydrates']['grams']);
    $fatsDiff = abs($totalMacros['fats'] - $targetMacros['fats']['grams']);
    
    if ($proteinDiff > $targetMacros['protein']['grams'] * $tolerance) {
        $errors[] = sprintf('Proteína fuera de rango: objetivo %dg, obtenido %dg (diff: %dg)', 
            $targetMacros['protein']['grams'], 
            $totalMacros['protein'],
            $proteinDiff
        );
    }
    
    if ($carbsDiff > $targetMacros['carbohydrates']['grams'] * $tolerance) {
        $errors[] = sprintf('Carbohidratos fuera de rango: objetivo %dg, obtenido %dg (diff: %dg)', 
            $targetMacros['carbohydrates']['grams'], 
            $totalMacros['carbs'],
            $carbsDiff
        );
    }
    
    if ($fatsDiff > $targetMacros['fats']['grams'] * $tolerance) {
        $errors[] = sprintf('Grasas fuera de rango: objetivo %dg, obtenido %dg (diff: %dg)', 
            $targetMacros['fats']['grams'], 
            $totalMacros['fats'],
            $fatsDiff
        );
    }
    
    // NUEVO: Validación de balance entre comidas
    $mealDistribution = ['Desayuno' => 0.30, 'Almuerzo' => 0.40, 'Cena' => 0.30];
    foreach ($planData['nutritionPlan']['meals'] as $mealName => $mealData) {
        if (isset($mealDistribution[$mealName])) {
            $expectedPercentage = $mealDistribution[$mealName];
            $expectedCalories = $targetMacros['calories'] * $expectedPercentage;
            
            // Calcular calorías reales de esta comida
            $mealCalories = 0;
            foreach ($mealData as $category => $categoryData) {
                if (isset($categoryData['options'][0])) {
                    $mealCalories += $categoryData['options'][0]['calories'] ?? 0;
                }
            }
            
            $calorieDiff = abs($mealCalories - $expectedCalories);
            if ($calorieDiff > $expectedCalories * 0.15) { // 15% de tolerancia
                $warnings[] = sprintf('%s desequilibrado: esperado ~%d kcal, tiene %d kcal', 
                    $mealName, 
                    round($expectedCalories), 
                    $mealCalories
                );
            }
        }
    }
    
    return [
        'is_valid' => empty($errors),
        'errors' => $errors,
        'warnings' => $warnings,
        'total_macros' => $totalMacros,
        'food_appearances' => $foodAppearances,
        'meals_with_eggs' => $mealsWithEggs
    ];
}

 private function isFoodHighBudget($foodName): bool
    {
        $highBudgetFoods = [
            'salmón', 'salmon', 'pechuga de pollo', 'claras de huevo', 
            'yogurt griego', 'yogur griego', 'proteína', 'whey',
            'quinua', 'quinoa', 'avena orgánica', 'pan integral artesanal',
            'aceite de oliva extra virgen', 'almendras', 'nueces', 
            'pistachos', 'aguacate hass', 'palta hass'
        ];
        
        foreach ($highBudgetFoods as $food) {
            if (str_contains($foodName, $food)) {
                return true;
            }
        }
        return false;
    }



 private function isFoodLowBudget($foodName): bool
    {
        $lowBudgetFoods = [
            'huevo entero', 'pollo muslo', 'muslos', 'atún en lata', 
            'carne molida', 'arroz blanco', 'papa', 'fideos',
            'avena tradicional', 'tortillas de maíz', 'pan de molde',
            'aceite vegetal', 'maní', 'cacahuate', 'frijoles', 'lentejas'
        ];
        
        foreach ($lowBudgetFoods as $food) {
            if (str_contains($foodName, $food)) {
                return true;
            }
        }
        return false;
    }

   private function extractPersonalizationData($profile, $userName): array
    {
        return [
            'personal_data' => [
                'name' => $userName,
                'preferred_name' => $userName,
                'goal' => $profile->goal,
                'age' => (int)$profile->age,
                'sex' => strtolower($profile->sex),
                'weight' => (float)$profile->weight,
                'height' => (float)$profile->height,
                'country' => $profile->pais ?? 'No especificado',
                'bmi' => $this->calculateBMI($profile->weight, $profile->height),
                'age_group' => $this->getAgeGroup($profile->age),
                'sex_normalized' => $profile->sex === 'Masculino' ? 'masculino' : 'femenino'
            ],
            'activity_data' => [
                'weekly_activity' => $profile->weekly_activity,
                'sports' => is_string($profile->sport) ? json_decode($profile->sport, true) : ($profile->sport ?? []),
                'training_frequency' => $profile->training_frequency ?? 'No especificado'
            ],
            'meal_structure' => [
                'meal_count' => $profile->meal_count,
                'breakfast_time' => $profile->breakfast_time,
                'lunch_time' => $profile->lunch_time,
                'dinner_time' => $profile->dinner_time,
                'eats_out' => $profile->eats_out
            ],
            'dietary_preferences' => [
                'dietary_style' => $profile->dietary_style ?? 'Omnívoro',
                'budget' => $profile->budget,
                'disliked_foods' => $profile->disliked_foods ?? '',
                'has_allergies' => $profile->has_allergies ?? false,
                'allergies' => $profile->allergies ?? '',
                'has_medical_condition' => $profile->has_medical_condition ?? false,
                'medical_condition' => $profile->medical_condition ?? ''
            ],
            'emotional_data' => [
                'communication_style' => $profile->communication_style,
                'diet_difficulties' => is_string($profile->diet_difficulties) 
                    ? json_decode($profile->diet_difficulties, true) 
                    : ($profile->diet_difficulties ?? []),
                'diet_motivations' => is_string($profile->diet_motivations) 
                    ? json_decode($profile->diet_motivations, true) 
                    : ($profile->diet_motivations ?? [])
            ],
            'created_at' => now()
        ];
    }
    
    private function getAgeGroup($age): string
    {
        if (!$age) return 'desconocido';
        if ($age < 20) return 'juvenil';
        if ($age < 30) return 'adulto_joven';
        if ($age < 50) return 'adulto';
        if ($age < 65) return 'adulto_mayor';
        return 'senior';
    }
      
    private function calculateCompleteNutritionalPlan($profile, $userName): array
    {
        $this->validateAnthropometricData($profile);
        $userName = $profile->user->name ?? 'Usuario';

        $basicData = [
            'age' => (int)$profile->age,
            'sex' => strtolower($profile->sex),
            'weight' => (float)$profile->weight,
            'height' => (float)$profile->height,
            'activity_level' => $profile->weekly_activity,
            'goal' => $profile->goal,
            'country' => $profile->pais ?? 'No especificado',
            
            'anthropometric_data' => [
                'bmi' => $this->calculateBMI($profile->weight, $profile->height),
                'bmr_category' => $this->getBMRCategory($profile->age),
                'weight_status' => $this->getWeightStatus($this->calculateBMI($profile->weight, $profile->height)),
                'ideal_weight_range' => $this->calculateIdealWeightRange($profile->height, $profile->sex)
            ],
            
            'health_status' => [
                'medical_condition' => $profile->medical_condition ?? 'Ninguna',
                'allergies' => $profile->allergies ?? 'Ninguna',
                'has_medical_condition' => $profile->has_medical_condition ?? false,
                'has_allergies' => $profile->has_allergies ?? false
            ],
            
            'preferences' => [
                'name' => $userName,
                'preferred_name' => $userName,
                'dietary_style' => $profile->dietary_style ?? 'Omnívoro',
                'disliked_foods' => $profile->disliked_foods ?? 'Ninguno',
                'budget' => $profile->budget ?? 'Medio',
                'meal_count' => $profile->meal_count ?? '3 comidas principales',
                'eats_out' => $profile->eats_out ?? 'A veces',
                'communication_style' => $profile->communication_style ?? 'Cercana'
            ],
            
            'meal_times' => [
                'breakfast_time' => $profile->breakfast_time ?? '07:00',
                'lunch_time' => $profile->lunch_time ?? '13:00',
                'dinner_time' => $profile->dinner_time ?? '20:00'
            ],
            
            'sports_data' => [
                'sports' => is_string($profile->sport) ? json_decode($profile->sport, true) : ($profile->sport ?? []),
                'training_frequency' => $profile->training_frequency ?? 'Moderado'
            ],
            
            'emotional_profile' => [
                'diet_difficulties' => is_string($profile->diet_difficulties) 
                    ? json_decode($profile->diet_difficulties, true) 
                    : ($profile->diet_difficulties ?? []),
                'diet_motivations' => is_string($profile->diet_motivations) 
                    ? json_decode($profile->diet_motivations, true) 
                    : ($profile->diet_motivations ?? [])
            ]
        ];

        $tmb = $this->calculateTMB($basicData['sex'], $basicData['weight'], $basicData['height'], $basicData['age']);
        $activityFactor = $this->getExactActivityFactor($basicData['activity_level']);
        $get = $tmb * $activityFactor;
        $adjustedCalories = $this->adjustCaloriesForGoal($get, $basicData['goal'], $basicData['weight'], $basicData['anthropometric_data']['weight_status']);
        $macros = $this->calculatePersonalizedMacronutrients($adjustedCalories, $basicData['weight'], $basicData['goal'], $basicData['preferences']['dietary_style'], $basicData['anthropometric_data']);
        
        return [
            'basic_data' => $basicData,
            'tmb' => round($tmb),
            'activity_factor' => $activityFactor,
            'get' => round($get),
            'target_calories' => round($adjustedCalories),
            'macros' => $macros,
            'month' => 1,
            'calculation_date' => now(),
            'personalization_level' => 'ultra_high',
            'anthropometric_analysis' => [
                'tmb_per_kg' => round($tmb / $basicData['weight'], 2),
                'calories_per_kg' => round($adjustedCalories / $basicData['weight'], 2),
                'protein_per_kg' => round($macros['protein']['grams'] / $basicData['weight'], 2),
                'recommended_adjustments' => $this->getAnthropometricRecommendations($basicData['anthropometric_data'], $basicData['goal'])
            ]
        ];
    }

    private function validateAnthropometricData($profile): void
    {
        $errors = [];
        
        if (!$profile->age || $profile->age < 16 || $profile->age > 80) {
            $errors[] = "Edad inválida: {$profile->age}. Debe estar entre 16 y 80 años.";
        }
        
        if (!$profile->weight || $profile->weight < 30 || $profile->weight > 300) {
            $errors[] = "Peso inválido: {$profile->weight}kg. Debe estar entre 30 y 300 kg.";
        }
        
        if (!$profile->height || $profile->height < 120 || $profile->height > 250) {
            $errors[] = "Altura inválida: {$profile->height}cm. Debe estar entre 120 y 250 cm.";
        }
        
        if (!$profile->sex || !in_array(strtolower($profile->sex), ['masculino', 'femenino'])) {
            $errors[] = "Sexo inválido: {$profile->sex}. Debe ser Masculino o Femenino.";
        }
        
        if ($profile->weight && $profile->height) {
            $bmi = $this->calculateBMI($profile->weight, $profile->height);
            if ($bmi < 15 || $bmi > 50) {
                $errors[] = "BMI extremo: {$bmi}. Los cálculos pueden no ser precisos.";
            }
        }
        
        if (!empty($errors)) {
            Log::error("Datos antropométricos inválidos para usuario {$profile->user_id}", $errors);
            throw new \Exception("Datos antropométricos inválidos: " . implode(', ', $errors));
        }
        
        Log::info("Datos antropométricos validados correctamente", [
            'user_id' => $profile->user_id,
            'age' => $profile->age,
            'weight' => $profile->weight,
            'height' => $profile->height,
            'sex' => $profile->sex,
            'bmi' => round($this->calculateBMI($profile->weight, $profile->height), 2)
        ]);
    }

    private function calculateBMI($weight, $height): float
    {
        if (!$weight || !$height) return 0;
        $heightInMeters = $height / 100;
        return $weight / ($heightInMeters * $heightInMeters);
    }

    private function getWeightStatus($bmi): string
    {
        if ($bmi < 18.5) return 'bajo_peso';
        if ($bmi < 25) return 'peso_normal';
        if ($bmi < 30) return 'sobrepeso';
        if ($bmi < 35) return 'obesidad_grado_1';
        if ($bmi < 40) return 'obesidad_grado_2';
        return 'obesidad_grado_3';
    }

    private function calculateIdealWeightRange($height, $sex): array
    {
        if (!$height) return ['min' => 0, 'max' => 0];
        
        $heightInMeters = $height / 100;
        $minWeight = 18.5 * ($heightInMeters * $heightInMeters);
        $maxWeight = 24.9 * ($heightInMeters * $heightInMeters);
        
        return [
            'min' => round($minWeight, 1),
            'max' => round($maxWeight, 1)
        ];
    }

    private function getBMRCategory($age): string
    {
        if ($age < 20) return 'juvenil';
        if ($age < 30) return 'adulto_joven';
        if ($age < 50) return 'adulto';
        if ($age < 65) return 'adulto_mayor';
        return 'senior';
    }

    private function getAnthropometricRecommendations($anthropometricData, $goal): array
    {
        $recommendations = [];
        
        $bmi = $anthropometricData['bmi'];
        $weightStatus = $anthropometricData['weight_status'];
        
        if ($weightStatus === 'bajo_peso' && str_contains(strtolower($goal), 'bajar grasa')) {
            $recommendations[] = "ADVERTENCIA: BMI bajo ({$bmi}). Considerar objetivo de ganancia de peso saludable.";
        }
        
        if ($weightStatus === 'obesidad_grado_2' || $weightStatus === 'obesidad_grado_3') {
            $recommendations[] = "BMI alto ({$bmi}). Déficit calórico conservador recomendado.";
        }
        
        if ($bmi > 30 && str_contains(strtolower($goal), 'aumentar músculo')) {
            $recommendations[] = "Considerar recomposición corporal: pérdida de grasa + ganancia muscular simultánea.";
        }
        
        return $recommendations;
    }

    private function calculateTMB($sex, $weight, $height, $age): float
    {
        if ($sex === 'masculino') {
            return 66.473 + (13.751 * $weight) + (5.003 * $height) - (6.755 * $age);
        } else {
            return 655.0955 + (9.463 * $weight) + (1.8496 * $height) - (4.6756 * $age);
        }
    }

    private function getExactActivityFactor($weeklyActivity): float
    {
        $factorMap = [
            'No me muevo y no entreno' => 1.20,
            'Oficina + entreno 1-2 veces' => 1.37,
            'Oficina + entreno 3-4 veces' => 1.45,
            'Oficina + entreno 5-6 veces' => 1.55,
            'Trabajo activo + entreno 1-2 veces' => 1.55,
            'Trabajo activo + entreno 3-4 veces' => 1.72,
            'Trabajo muy físico + entreno 5-6 veces' => 1.90
        ];

        if (isset($factorMap[$weeklyActivity])) {
            return $factorMap[$weeklyActivity];
        }

        foreach ($factorMap as $activity => $factor) {
            if (str_contains($weeklyActivity, $activity)) {
                return $factor;
            }
        }

        Log::warning("Factor de actividad no encontrado: {$weeklyActivity}. Usando valor por defecto.");
        return 1.37;
    }

    private function adjustCaloriesForGoal($get, $goal, $weight, $weightStatus): float
    {
        $goalLower = strtolower($goal);
        
        if (str_contains($goalLower, 'bajar grasa')) {
            if ($weightStatus === 'obesidad_grado_2' || $weightStatus === 'obesidad_grado_3') {
                return $get * 0.75;
            } else {
                return $get * 0.80;
            }
        } elseif (str_contains($goalLower, 'aumentar músculo')) {
            if ($weightStatus === 'bajo_peso') {
                return $get * 1.15;
            } else {
                return $get * 1.10;
            }
        } else {
            return $get;
        }
    }

    private function calculatePersonalizedMacronutrients($calories, $weight, $goal, $dietaryStyle, $anthropometricData): array
    {
        $dietStyle = strtolower($dietaryStyle);
        $weightStatus = $anthropometricData['weight_status'];
        $bmi = $anthropometricData['bmi'];
        
        if (str_contains(strtolower($goal), 'bajar grasa')) {
            $proteinMultiplier = 2.2;
            
            if ($weightStatus === 'obesidad_grado_1' || $weightStatus === 'obesidad_grado_2' || $weightStatus === 'obesidad_grado_3') {
                $proteinMultiplier = 2.4;
            }
        } elseif (str_contains(strtolower($goal), 'aumentar músculo')) {
            $proteinMultiplier = 2.0;
            
            if ($weightStatus === 'bajo_peso') {
                $proteinMultiplier = 1.8;
            }
        } else {
            $proteinMultiplier = 1.8;
        }

        if ($dietStyle === 'vegano' || $dietStyle === 'vegetariano') {
            $proteinMultiplier += 0.2;
        }

        $proteinGrams = $weight * $proteinMultiplier;
        $proteinCalories = $proteinGrams * 4;

        $fatPercentage = 0.25;
        
        if (str_contains($dietStyle, 'keto')) {
            $fatPercentage = 0.70;
        } elseif ($dietStyle === 'vegano') {
            $fatPercentage = 0.30;
        } elseif ($weightStatus === 'bajo_peso') {
            $fatPercentage = 0.30;
        }

        $minFatGrams = $weight * 0.8;
        $fatCalories = $calories * $fatPercentage;
        $fatGrams = max($minFatGrams, $fatCalories / 9);
        $fatCalories = $fatGrams * 9;

        if (str_contains($dietStyle, 'keto')) {
            $carbGrams = min(50, max(20, ($calories - $proteinCalories - $fatCalories) / 4));
            $carbCalories = $carbGrams * 4;
            
            $fatCalories = $calories - $proteinCalories - $carbCalories;
            $fatGrams = $fatCalories / 9;
        } else {
            $carbCalories = $calories - $proteinCalories - $fatCalories;
            $carbGrams = max(0, $carbCalories / 4);
        }

        return [
            'calories' => round($calories),
            'protein' => [
                'grams' => round($proteinGrams),
                'calories' => round($proteinCalories),
                'percentage' => round(($proteinCalories / $calories) * 100, 1),
                'per_kg' => round($proteinMultiplier, 2)
            ],
            'fats' => [
                'grams' => round($fatGrams),
                'calories' => round($fatCalories),
                'percentage' => round(($fatCalories / $calories) * 100, 1),
                'per_kg' => round($fatGrams / $weight, 2)
            ],
            'carbohydrates' => [
                'grams' => round($carbGrams),
                'calories' => round($carbCalories),
                'percentage' => round(($carbCalories / $calories) * 100, 1),
                'per_kg' => round($carbGrams / $weight, 2)
            ],
            'dietary_adjustments' => [
                'style' => $dietaryStyle,
                'protein_multiplier' => $proteinMultiplier,
                'fat_percentage' => $fatPercentage,
                'anthropometric_considerations' => [
                    'weight_status' => $weightStatus,
                    'bmi' => round($bmi, 1),
                    'adjustments_applied' => $this->getAppliedAdjustments($weightStatus, $goal)
                ]
            ]
        ];
    }

    private function getAppliedAdjustments($weightStatus, $goal): array
    {
        $adjustments = [];
        
        if ($weightStatus === 'obesidad_grado_2' || $weightStatus === 'obesidad_grado_3') {
            $adjustments[] = 'Proteína aumentada para preservar masa magra';
            if (str_contains(strtolower($goal), 'bajar grasa')) {
                $adjustments[] = 'Déficit calórico conservador para obesidad severa';
            }
        }
        
        if ($weightStatus === 'bajo_peso') {
            $adjustments[] = 'Grasas aumentadas para ganancia de peso saludable';
            if (str_contains(strtolower($goal), 'aumentar músculo')) {
                $adjustments[] = 'Superávit calórico mayor para recuperación';
            }
        }
        
        return $adjustments;
    }

 private function generateUltraPersonalizedNutritionalPlan($profile, $nutritionalData, $userName, $attemptNumber = 1): ?array
    {
        $prompt = $this->buildUltraPersonalizedPrompt($profile, $nutritionalData, $userName, $attemptNumber);

        $response = Http::withToken(env('OPENAI_API_KEY'))
            ->timeout(150)
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => 'gpt-4o',
                'messages' => [['role' => 'user', 'content' => $prompt]],
                'response_format' => ['type' => 'json_object'],
                'temperature' => 0.3, // Baja temperatura para más precisión
            ]);

        if ($response->successful()) {
            $planData = json_decode($response->json('choices.0.message.content'), true);
            
            // Agregar datos nutricionales calculados al plan
            $planData['nutritional_calculations'] = $nutritionalData;
            
            return $planData;
        }
        
        Log::error("Fallo en la llamada a OpenAI para generar plan personalizado", [
            'status' => $response->status(), 
            'body' => $response->body(),
            'attempt' => $attemptNumber
        ]);
        return null;
    }

 

    /**
     * CALCULADORA DINÁMICA DE PORCIONES EXACTAS
     */
    private function calculateMealSpecificPortions($macros, $budget): array
    {
        // Distribución de macros por comida (basada en cronobiología nutricional)
        $mealDistribution = [
            'desayuno' => ['protein' => 0.25, 'carbs' => 0.35, 'fats' => 0.30],
            'almuerzo' => ['protein' => 0.45, 'carbs' => 0.45, 'fats' => 0.40], 
            'cena' => ['protein' => 0.30, 'carbs' => 0.20, 'fats' => 0.30]
        ];

        $foodDatabase = $this->getFoodNutritionalDatabase($budget);
        $mealPortions = [];
        
        foreach ($mealDistribution as $meal => $distribution) {
            $targetProtein = $macros['protein']['grams'] * $distribution['protein'];
            $targetCarbs = $macros['carbohydrates']['grams'] * $distribution['carbs'];
            $targetFats = $macros['fats']['grams'] * $distribution['fats'];
            
            $mealPortions[$meal] = [
                'proteins' => $this->calculateProteinPortions($targetProtein, $foodDatabase[$meal]['proteins']),
                'carbohydrates' => $this->calculateCarbPortions($targetCarbs, $foodDatabase[$meal]['carbohydrates']),
                'fats' => $this->calculateFatPortions($targetFats, $foodDatabase[$meal]['fats'])
            ];
        }
        
        return $mealPortions;
    }

    /**
     * Base de datos nutricional específica por presupuesto
     */
    private function getFoodNutritionalDatabase($budget): array
    {
        $isHighBudget = str_contains(strtolower($budget), 'alto');
        
        return [
            'desayuno' => [
                'proteins' => $isHighBudget ? [
                    'claras_pasteurizadas' => ['protein_per_100g' => 11, 'calories_per_100g' => 52, 'fats_per_100g' => 0, 'carbs_per_100g' => 1],
                    'yogurt_griego' => ['protein_per_100g' => 13, 'calories_per_100g' => 90, 'fats_per_100g' => 3, 'carbs_per_100g' => 5],
                    'proteina_polvo' => ['protein_per_100g' => 80, 'calories_per_100g' => 380, 'fats_per_100g' => 2, 'carbs_per_100g' => 8]
                ] : [
                    'huevo_entero' => ['protein_per_100g' => 13, 'calories_per_100g' => 155, 'fats_per_100g' => 11, 'carbs_per_100g' => 1],
                    'queso_fresco' => ['protein_per_100g' => 18, 'calories_per_100g' => 185, 'fats_per_100g' => 10, 'carbs_per_100g' => 4],
                    'frijoles_refritos' => ['protein_per_100g' => 8, 'calories_per_100g' => 130, 'fats_per_100g' => 2, 'carbs_per_100g' => 20]
                ],
                'carbohydrates' => [
                    'avena_tradicional' => ['protein_per_100g' => 13, 'calories_per_100g' => 375, 'fats_per_100g' => 7, 'carbs_per_100g' => 67],
                    'pan_integral' => ['protein_per_100g' => 9, 'calories_per_100g' => 260, 'fats_per_100g' => 4, 'carbs_per_100g' => 47],
                    'tortillas_maiz' => ['protein_per_100g' => 6, 'calories_per_100g' => 250, 'fats_per_100g' => 3, 'carbs_per_100g' => 50]
                ],
                'fats' => $isHighBudget ? [
                    'aceite_oliva_extra_virgen' => ['protein_per_100g' => 0, 'calories_per_100g' => 900, 'fats_per_100g' => 100, 'carbs_per_100g' => 0],
                    'almendras' => ['protein_per_100g' => 21, 'calories_per_100g' => 575, 'fats_per_100g' => 50, 'carbs_per_100g' => 10],
                    'aguacate_hass' => ['protein_per_100g' => 2, 'calories_per_100g' => 200, 'fats_per_100g' => 19, 'carbs_per_100g' => 9]
                ] : [
                    'aceite_vegetal' => ['protein_per_100g' => 0, 'calories_per_100g' => 800, 'fats_per_100g' => 92, 'carbs_per_100g' => 0],
                    'mani' => ['protein_per_100g' => 26, 'calories_per_100g' => 600, 'fats_per_100g' => 47, 'carbs_per_100g' => 20],
                    'aguacate' => ['protein_per_100g' => 2, 'calories_per_100g' => 140, 'fats_per_100g' => 13, 'carbs_per_100g' => 7]
                ]
            ],
            'almuerzo' => [
                'proteins' => $isHighBudget ? [
                    'salmon_fresco' => ['protein_per_100g' => 30, 'calories_per_100g' => 185, 'fats_per_100g' => 8, 'carbs_per_100g' => 0],
                    'pechuga_pollo_premium' => ['protein_per_100g' => 31, 'calories_per_100g' => 165, 'fats_per_100g' => 4, 'carbs_per_100g' => 0],
                    'lomo_res' => ['protein_per_100g' => 30, 'calories_per_100g' => 195, 'fats_per_100g' => 8, 'carbs_per_100g' => 0]
                ] : [
                    'pollo_muslos' => ['protein_per_100g' => 25, 'calories_per_100g' => 180, 'fats_per_100g' => 10, 'carbs_per_100g' => 0],
                    'carne_molida' => ['protein_per_100g' => 26, 'calories_per_100g' => 200, 'fats_per_100g' => 10, 'carbs_per_100g' => 0],
                    'pescado_bonito' => ['protein_per_100g' => 25, 'calories_per_100g' => 140, 'fats_per_100g' => 4, 'carbs_per_100g' => 0]
                ],
                'carbohydrates' => [
                    'arroz_blanco' => ['protein_per_100g' => 7, 'calories_per_100g' => 350, 'fats_per_100g' => 1, 'carbs_per_100g' => 78],
                    'papa_cocida' => ['protein_per_100g' => 2, 'calories_per_100g' => 78, 'fats_per_100g' => 0, 'carbs_per_100g' => 18],
                    'quinua' => ['protein_per_100g' => 14, 'calories_per_100g' => 365, 'fats_per_100g' => 6, 'carbs_per_100g' => 64]
                ],
                'fats' => $isHighBudget ? [
                    'aceite_oliva_extra_virgen' => ['protein_per_100g' => 0, 'calories_per_100g' => 900, 'fats_per_100g' => 100, 'carbs_per_100g' => 0],
                    'almendras' => ['protein_per_100g' => 21, 'calories_per_100g' => 575, 'fats_per_100g' => 50, 'carbs_per_100g' => 10],
                    'aguacate_hass' => ['protein_per_100g' => 2, 'calories_per_100g' => 200, 'fats_per_100g' => 19, 'carbs_per_100g' => 9]
                ] : [
                    'aceite_vegetal' => ['protein_per_100g' => 0, 'calories_per_100g' => 800, 'fats_per_100g' => 92, 'carbs_per_100g' => 0],
                    'mani' => ['protein_per_100g' => 26, 'calories_per_100g' => 600, 'fats_per_100g' => 47, 'carbs_per_100g' => 20],
                    'aguacate' => ['protein_per_100g' => 2, 'calories_per_100g' => 140, 'fats_per_100g' => 13, 'carbs_per_100g' => 7]
                ]
            ],
            'cena' => [
                'proteins' => $isHighBudget ? [
                    'pescado_blanco_premium' => ['protein_per_100g' => 25, 'calories_per_100g' => 120, 'fats_per_100g' => 2, 'carbs_per_100g' => 0],
                    'pechuga_pavo' => ['protein_per_100g' => 28, 'calories_per_100g' => 135, 'fats_per_100g' => 2, 'carbs_per_100g' => 0],
                    'claras_pasteurizadas' => ['protein_per_100g' => 11, 'calories_per_100g' => 52, 'fats_per_100g' => 0, 'carbs_per_100g' => 1]
                ] : [
                    'atun_lata' => ['protein_per_100g' => 30, 'calories_per_100g' => 145, 'fats_per_100g' => 2, 'carbs_per_100g' => 0],
                    'huevo_entero' => ['protein_per_100g' => 13, 'calories_per_100g' => 155, 'fats_per_100g' => 11, 'carbs_per_100g' => 1],
                    'pollo_muslos' => ['protein_per_100g' => 25, 'calories_per_100g' => 180, 'fats_per_100g' => 10, 'carbs_per_100g' => 0]
                ],
                'carbohydrates' => [
                    'frijoles_cocidos' => ['protein_per_100g' => 8, 'calories_per_100g' => 120, 'fats_per_100g' => 1, 'carbs_per_100g' => 21],
                    'arroz_blanco' => ['protein_per_100g' => 7, 'calories_per_100g' => 350, 'fats_per_100g' => 1, 'carbs_per_100g' => 78]
                ],
                'fats' => $isHighBudget ? [
                    'aceite_oliva_extra_virgen' => ['protein_per_100g' => 0, 'calories_per_100g' => 900, 'fats_per_100g' => 100, 'carbs_per_100g' => 0],
                    'almendras' => ['protein_per_100g' => 21, 'calories_per_100g' => 575, 'fats_per_100g' => 50, 'carbs_per_100g' => 10]
                ] : [
                    'aceite_vegetal' => ['protein_per_100g' => 0, 'calories_per_100g' => 800, 'fats_per_100g' => 92, 'carbs_per_100g' => 0],
                    'mani' => ['protein_per_100g' => 26, 'calories_per_100g' => 600, 'fats_per_100g' => 47, 'carbs_per_100g' => 20]
                ]
            ]
        ];
    }

    /**
     * Calcular porciones específicas de proteínas
     */
    private function calculateProteinPortions($targetProteinGrams, $proteinSources): array
    {
        $portions = [];
        
        foreach ($proteinSources as $foodName => $nutrition) {
            $gramsNeeded = ($targetProteinGrams / $nutrition['protein_per_100g']) * 100;
            $calories = ($gramsNeeded / 100) * $nutrition['calories_per_100g'];
            $fats = ($gramsNeeded / 100) * $nutrition['fats_per_100g'];
            $carbs = ($gramsNeeded / 100) * $nutrition['carbs_per_100g'];
            
            $displayName = $this->formatFoodDisplayName($foodName);
            $portion = $this->formatPortion($foodName, $gramsNeeded);
            
            $portions[] = [
                'name' => $displayName,
                'portion' => $portion,
                'calories' => round($calories),
                'protein' => round($targetProteinGrams),
                'fats' => round($fats, 1),
                'carbohydrates' => round($carbs, 1)
            ];
        }
        
        return $portions;
    }

    /**
     * Calcular porciones específicas de carbohidratos
     */
    private function calculateCarbPortions($targetCarbGrams, $carbSources): array
    {
        $portions = [];
        
        foreach ($carbSources as $foodName => $nutrition) {
            $gramsNeeded = ($targetCarbGrams / $nutrition['carbs_per_100g']) * 100;
            $calories = ($gramsNeeded / 100) * $nutrition['calories_per_100g'];
            $protein = ($gramsNeeded / 100) * $nutrition['protein_per_100g'];
            $fats = ($gramsNeeded / 100) * $nutrition['fats_per_100g'];
            
            $displayName = $this->formatFoodDisplayName($foodName);
            $portion = $this->formatPortion($foodName, $gramsNeeded);
            
            $portions[] = [
                'name' => $displayName,
                'portion' => $portion,
                'calories' => round($calories),
                'protein' => round($protein, 1),
                'fats' => round($fats, 1),
                'carbohydrates' => round($targetCarbGrams)
            ];
        }
        
        return $portions;
    }

    /**
     * Calcular porciones específicas de grasas
     */
    private function calculateFatPortions($targetFatGrams, $fatSources): array
    {
        $portions = [];
        
        foreach ($fatSources as $foodName => $nutrition) {
            $gramsNeeded = ($targetFatGrams / $nutrition['fats_per_100g']) * 100;
            $calories = ($gramsNeeded / 100) * $nutrition['calories_per_100g'];
            $protein = ($gramsNeeded / 100) * $nutrition['protein_per_100g'];
            $carbs = ($gramsNeeded / 100) * $nutrition['carbs_per_100g'];
            
            $displayName = $this->formatFoodDisplayName($foodName);
            $portion = $this->formatPortion($foodName, $gramsNeeded);
            
            $portions[] = [
                'name' => $displayName,
                'portion' => $portion,
                'calories' => round($calories),
                'protein' => round($protein, 1),
                'fats' => round($targetFatGrams),
                'carbohydrates' => round($carbs, 1)
            ];
        }
        
        return $portions;
    }

    /**
     * Formatear nombres para mostrar
     */
    private function formatFoodDisplayName($foodName): string
    {
        $names = [
            'huevo_entero' => 'Huevo entero',
            'salmon_fresco' => 'Salmón fresco',
            'claras_pasteurizadas' => 'Claras pasteurizadas',
            'aceite_oliva_extra_virgen' => 'Aceite de oliva extra virgen',
            'aceite_vegetal' => 'Aceite vegetal',
            'avena_tradicional' => 'Avena tradicional',
            'arroz_blanco' => 'Arroz blanco',
            'tortillas_maiz' => 'Tortillas de maíz',
            'yogurt_griego' => 'Yogurt griego',
            'proteina_polvo' => 'Proteína en polvo',
            'queso_fresco' => 'Queso fresco',
            'frijoles_refritos' => 'Frijoles refritos',
            'pan_integral' => 'Pan integral',
            'almendras' => 'Almendras',
            'aguacate_hass' => 'Aguacate Hass',
            'mani' => 'Maní',
            'aguacate' => 'Aguacate',
            'pechuga_pollo_premium' => 'Pechuga de pollo premium',
            'lomo_res' => 'Lomo de res',
            'pollo_muslos' => 'Pollo muslos',
            'carne_molida' => 'Carne molida',
            'pescado_bonito' => 'Pescado bonito',
            'papa_cocida' => 'Papa cocida',
            'quinua' => 'Quinua',
            'pescado_blanco_premium' => 'Pescado blanco premium',
            'pechuga_pavo' => 'Pechuga de pavo',
            'atun_lata' => 'Atún en lata',
            'frijoles_cocidos' => 'Frijoles cocidos'
        ];
        
        return $names[$foodName] ?? ucwords(str_replace('_', ' ', $foodName));
    }

    /**
     * Formatear porciones con referencia visual
     */
    private function formatPortion($foodName, $grams): string
    {
        $portions = [
            'huevo_entero' => function($g) { 
                $units = round($g / 50);
                return round($g) . "g ({$units} " . ($units == 1 ? 'unidad' : 'unidades') . ")";
            },
            'tortillas_maiz' => function($g) {
                $units = round($g / 30);
                return round($g) . "g ({$units} " . ($units == 1 ? 'tortilla' : 'tortillas') . ")";
            },
            'aceite_vegetal' => function($g) {
                $ml = round($g * 1.08);
                $tbsp = round($ml / 15);
                return "{$ml}ml ({$tbsp} " . ($tbsp == 1 ? 'cucharada' : 'cucharadas') . ")";
            },
            'aceite_oliva_extra_virgen' => function($g) {
                $ml = round($g * 1.08);
                $tbsp = round($ml / 15);
                return "{$ml}ml ({$tbsp} " . ($tbsp == 1 ? 'cucharada' : 'cucharadas') . ")";
            },
            'pan_integral' => function($g) {
                $slices = round($g / 30);
                return round($g) . "g ({$slices} " . ($slices == 1 ? 'rebanada' : 'rebanadas') . ")";
            },
            'almendras' => function($g) {
                $units = round($g / 1.2);
                return round($g) . "g ({$units} unidades)";
            },
            'mani' => function($g) {
                $units = round($g / 0.8);
                return round($g) . "g ({$units} unidades)";
            }
        ];
        
        if (isset($portions[$foodName])) {
            return $portions[$foodName]($grams);
        }
        
        return round($grams) . "g (peso en crudo)";
    }

    private function buildUltraPersonalizedPrompt($profile, $nutritionalData, $userName, $attemptNumber = 1): string
    {
        $macros = $nutritionalData['macros'];
        $basicData = $nutritionalData['basic_data'];
        
        $preferredName = $userName;
        $communicationStyle = $basicData['preferences']['communication_style'];
        $sports = !empty($basicData['sports_data']['sports']) ? implode(', ', $basicData['sports_data']['sports']) : 'Ninguno especificado';
        $mealTimes = $basicData['meal_times'];
        $difficulties = !empty($basicData['emotional_profile']['diet_difficulties']) ? implode(', ', $basicData['emotional_profile']['diet_difficulties']) : 'Ninguna especificada';
        $motivations = !empty($basicData['emotional_profile']['diet_motivations']) ? implode(', ', $basicData['emotional_profile']['diet_motivations']) : 'Ninguna especificada';
        
        $budget = $basicData['preferences']['budget'];
        $budgetType = str_contains(strtolower($budget), 'bajo') ? 'BAJO' : 'ALTO';
        
        // Obtener listas de alimentos específicas
        $allowedFoods = $this->getAllowedFoodsByBudget($budgetType);
        $prohibitedFoods = $this->getProhibitedFoodsByBudget($budgetType);
        
        $dietaryInstructions = $this->getDetailedDietaryInstructions($basicData['preferences']['dietary_style']);
        $budgetInstructions = $this->getDetailedBudgetInstructions($budget, $basicData['country']);
        $communicationInstructions = $this->getCommunicationStyleInstructions($communicationStyle, $preferredName);
        $countrySpecificFoods = $this->getCountrySpecificFoods($basicData['country'], $budget);

        // Agregar énfasis en intentos posteriores
        $attemptEmphasis = $attemptNumber > 1 ? "
        ⚠️ ATENCIÓN: Este es el intento #{$attemptNumber}. Los intentos anteriores fallaron por no cumplir las reglas.
        ES CRÍTICO que sigas TODAS las instrucciones AL PIE DE LA LETRA.
        " : "";

        return "
        Eres un nutricionista experto especializado en planes alimentarios ULTRA-PERSONALIZADOS. 
        Tu cliente se llama {$preferredName} y has trabajado con él/ella durante meses.
        
        {$attemptEmphasis}
        
        🔴 REGLAS CRÍTICAS OBLIGATORIAS - PRESUPUESTO {$budgetType} 🔴
        
        **REGLA #1: ALIMENTOS SEGÚN PRESUPUESTO {$budgetType}**
        " . ($budgetType === 'ALTO' ? "
        ✅ OBLIGATORIO usar ESTOS alimentos premium:
        PROTEÍNAS DESAYUNO: Claras de huevo pasteurizadas, Yogurt griego, Proteína whey
        PROTEÍNAS ALMUERZO/CENA: Pechuga de pollo, Salmón fresco, Atún fresco, Carne magra de res
        CARBOHIDRATOS: Quinua, Avena orgánica, Pan integral artesanal, Camote, Arroz integral
        GRASAS: Aceite de oliva extra virgen, Almendras, Nueces, Aguacate hass
        
        ❌ PROHIBIDO usar: Huevo entero, Pollo muslo, Atún en lata, Aceite vegetal, Maní, Arroz blanco, Pan de molde
        " : "
        ✅ OBLIGATORIO usar ESTOS alimentos económicos:
        PROTEÍNAS: Huevo entero (MAX 1 comida), Pollo muslo, Atún en lata, Carne molida
        CARBOHIDRATOS: Arroz blanco, Papa, Avena tradicional, Tortillas de maíz, Fideos, Frijoles
        GRASAS: Aceite vegetal, Maní, Aguacate pequeño (cuando esté en temporada)
        
        ❌ PROHIBIDO usar: Salmón, Pechuga de pollo, Quinua, Almendras, Aceite de oliva extra virgen, Proteína en polvo
        ") . "
        
        **REGLA #2: VARIEDAD OBLIGATORIA**
        - Huevos (cualquier tipo): MÁXIMO 1 comida del día
        - NO repetir la misma proteína en más de 2 comidas
        - Cada comida debe tener opciones diferentes
        
        **REGLA #3: MACROS EXACTOS QUE DEBEN CUMPLIRSE**
        La suma total del día DEBE ser:
        - Proteínas: {$macros['protein']['grams']}g (tolerancia máxima ±5g)
        - Carbohidratos: {$macros['carbohydrates']['grams']}g (tolerancia máxima ±10g)
        - Grasas: {$macros['fats']['grams']}g (tolerancia máxima ±5g)
        - Calorías totales: {$macros['calories']} kcal
        
        **DISTRIBUCIÓN POR COMIDA:**
        - Desayuno: 30% de los macros totales
        - Almuerzo: 40% de los macros totales  
        - Cena: 30% de los macros totales
        
        **INFORMACIÓN NUTRICIONAL CALCULADA:**
        - TMB: {$nutritionalData['tmb']} kcal
        - GET: {$nutritionalData['get']} kcal
        - Calorías Objetivo: {$nutritionalData['target_calories']} kcal
        - Factor de Actividad: {$nutritionalData['activity_factor']}
        
        **PERFIL DE {$preferredName}:**
        - Edad: {$basicData['age']} años, {$basicData['sex']}
        - Peso: {$basicData['weight']} kg, Altura: {$basicData['height']} cm
        - BMI: {$basicData['anthropometric_data']['bmi']} ({$basicData['anthropometric_data']['weight_status']})
        - País: {$basicData['country']}
        - Objetivo: {$basicData['goal']}
        - Deportes: {$sports}
        - Estilo alimentario: {$basicData['preferences']['dietary_style']}
        - Alimentos que NO le gustan: {$basicData['preferences']['disliked_foods']}
        - Alergias: {$basicData['health_status']['allergies']}
        - Come fuera: {$basicData['preferences']['eats_out']}
        - Dificultades: {$difficulties}
        - Motivaciones: {$motivations}
        
        {$budgetInstructions}
        {$dietaryInstructions}
        {$communicationInstructions}
        
        **ALIMENTOS ESPECÍFICOS PARA {$basicData['country']}:**
        {$countrySpecificFoods}
        
        **VERIFICACIÓN OBLIGATORIA ANTES DE RESPONDER:**
        1. ¿Todos los alimentos son del presupuesto {$budgetType}? ✓
        2. ¿Los huevos aparecen máximo 1 vez? ✓
        3. ¿Hay variedad entre comidas? ✓
        4. ¿La suma de proteínas es {$macros['protein']['grams']}g ±5g? ✓
        5. ¿La suma de carbohidratos es {$macros['carbohydrates']['grams']}g ±10g? ✓
        6. ¿La suma de grasas es {$macros['fats']['grams']}g ±5g? ✓
        
        **ESTRUCTURA JSON OBLIGATORIA:**
```json
        {
          \"nutritionPlan\": {
            \"personalizedMessage\": \"Mensaje personal para {$preferredName}...\",
            \"anthropometricSummary\": {
              \"clientName\": \"{$preferredName}\",
              \"age\": {$basicData['age']},
              \"sex\": \"{$basicData['sex']}\",
              \"weight\": {$basicData['weight']},
              \"height\": {$basicData['height']},
              \"bmi\": {$basicData['anthropometric_data']['bmi']},
              \"weightStatus\": \"{$basicData['anthropometric_data']['weight_status']}\",
              \"idealWeightRange\": {
                \"min\": {$basicData['anthropometric_data']['ideal_weight_range']['min']},
                \"max\": {$basicData['anthropometric_data']['ideal_weight_range']['max']}
              }
            },
            \"nutritionalSummary\": {
              \"tmb\": {$nutritionalData['tmb']},
              \"get\": {$nutritionalData['get']},
              \"targetCalories\": {$nutritionalData['target_calories']},
              \"goal\": \"{$basicData['goal']}\",
              \"monthlyProgression\": \"Mes 1 de 3 - Ajustes automáticos según progreso\",
              \"activityFactor\": \"{$nutritionalData['activity_factor']} ({$basicData['activity_level']})\",
              \"caloriesPerKg\": " . round($nutritionalData['target_calories'] / $basicData['weight'], 2) . ",
              \"proteinPerKg\": {$macros['protein']['per_kg']},
              \"specialConsiderations\": []
            },
            \"targetMacros\": {
              \"calories\": {$macros['calories']},
              \"protein\": {$macros['protein']['grams']},
              \"fats\": {$macros['fats']['grams']},
              \"carbohydrates\": {$macros['carbohydrates']['grams']},
              \"detailedBreakdown\": {
                \"protein\": {
                  \"grams\": {$macros['protein']['grams']},
                  \"calories\": {$macros['protein']['calories']},
                  \"percentage\": {$macros['protein']['percentage']},
                  \"perKg\": {$macros['protein']['per_kg']}
                },
                \"fats\": {
                  \"grams\": {$macros['fats']['grams']},
                  \"calories\": {$macros['fats']['calories']},
                  \"percentage\": {$macros['fats']['percentage']},
                  \"perKg\": {$macros['fats']['per_kg']}
                },
                \"carbohydrates\": {
                  \"grams\": {$macros['carbohydrates']['grams']},
                  \"calories\": {$macros['carbohydrates']['calories']},
                  \"percentage\": {$macros['carbohydrates']['percentage']},
                  \"perKg\": {$macros['carbohydrates']['per_kg']}
                }
              }
            },
            \"mealSchedule\": {
              \"breakfast\": \"{$mealTimes['breakfast_time']}\",
              \"lunch\": \"{$mealTimes['lunch_time']}\",
              \"dinner\": \"{$mealTimes['dinner_time']}\"
            },
            \"meals\": {
              \"Desayuno\": {
                \"Proteínas\": {
                  \"options\": [
                    // 3 opciones diferentes, respetando presupuesto {$budgetType}
                  ]
                },
                \"Carbohidratos\": {
                  \"options\": [
                    // 3 opciones diferentes
                  ]
                },
                \"Grasas\": {
                  \"options\": [
                    // 2-3 opciones diferentes
                  ]
                },
                \"Vegetales\": {
                  \"options\": [
                    {\"name\": \"Ensalada LIBRE\", \"portion\": \"Sin restricción\", \"calories\": 25, \"protein\": 2, \"fats\": 0, \"carbohydrates\": 5}
                  ]
                }
              },
              \"Almuerzo\": {
                // Similar estructura, DIFERENTES proteínas que en desayuno
              },
              \"Cena\": {
                // Similar estructura, DIFERENTES proteínas que en almuerzo
              }
            },
            \"personalizedTips\": {
              \"anthropometricGuidance\": \"Consejos basados en BMI {$basicData['anthropometric_data']['bmi']}\",
              \"difficultySupport\": \"Apoyo para: {$difficulties}\",
              \"motivationalElements\": \"Reforzando: {$motivations}\",
              \"eatingOutGuidance\": \"Guía para comer fuera ({$basicData['preferences']['eats_out']})\",
              \"ageSpecificAdvice\": \"Recomendaciones para {$basicData['age']} años\"
            }
          }
        }
    RECUERDA: Presupuesto {$budgetType} = usar SOLO alimentos de ese presupuesto.
    Genera el plan COMPLETO en español para {$preferredName}.
    ";
}
    


private function getAllowedFoodsByBudget($budgetType): array
{
    if ($budgetType === 'ALTO') {
        return [
            'proteinas' => ['Claras de huevo', 'Yogurt griego', 'Proteína whey', 'Pechuga de pollo', 'Salmón', 'Atún fresco'],
            'carbohidratos' => ['Quinua', 'Avena orgánica', 'Pan integral artesanal', 'Camote', 'Arroz integral'],
            'grasas' => ['Aceite de oliva extra virgen', 'Almendras', 'Nueces', 'Aguacate hass']
        ];
    } else {
        return [
            'proteinas' => ['Huevo entero', 'Pollo muslo', 'Atún en lata', 'Carne molida'],
            'carbohidratos' => ['Arroz blanco', 'Papa', 'Avena tradicional', 'Tortillas de maíz', 'Fideos'],
            'grasas' => ['Aceite vegetal', 'Maní', 'Aguacate pequeño']
        ];
    }
}

private function getProhibitedFoodsByBudget($budgetType): array
{
    if ($budgetType === 'ALTO') {
        return ['Huevo entero', 'Pollo muslo', 'Atún en lata', 'Aceite vegetal', 'Maní', 'Arroz blanco'];
    } else {
        return ['Salmón', 'Pechuga de pollo', 'Quinua', 'Almendras', 'Aceite de oliva extra virgen'];
    }
}




private function generateDeterministicPlan($nutritionalData, $profile, $userName): array
{
  
    


    $budget = strtolower($nutritionalData['basic_data']['preferences']['budget'] ?? '');
    $isLowBudget = str_contains($budget, 'bajo');
    $dietaryStyle = $nutritionalData['basic_data']['preferences']['dietary_style'] ?? 'Omnívoro';
    $userWeight = $nutritionalData['basic_data']['weight'];
    $macros = $nutritionalData['macros'];


    // Calcular distribución por comida
    $mealDistribution = [
        'Desayuno' => 0.30,
        'Almuerzo' => 0.40,
        'Cena' => 0.30
    ];
    
    $meals = [];
    
    foreach ($mealDistribution as $mealName => $percentage) {
        $mealProtein = round($macros['protein']['grams'] * $percentage);
        $mealCarbs = round($macros['carbohydrates']['grams'] * $percentage);
        $mealFats = round($macros['fats']['grams'] * $percentage);
 


         $meals[$mealName] = $this->generateDeterministicMealOptions(
            $mealName, 
            $mealProtein, 
            $mealCarbs, 
            $mealFats,
            $isLowBudget,
            $userWeight,
            $dietaryStyle // NUEVO PARÁMETRO
        );

         foreach ($meals[$mealName] as $category => &$categoryData) {
        if (isset($categoryData['options'])) {
            foreach ($categoryData['options'] as &$option) {
                if (!isset($option['isEgg'])) {
                    $this->addFoodMetadata($option, $isLowBudget);
                }
            }
        }
    }

        }
        


        return [
            'nutritionPlan' => [
                'personalizedMessage' => "Hola {$userName}, este es tu plan personalizado basado en cálculos precisos para asegurar que cumplas tus objetivos.",
                'meals' => $meals,
                'targetMacros' => [
                    'calories' => $macros['calories'],
                    'protein' => $macros['protein']['grams'],
                    'fats' => $macros['fats']['grams'],
                    'carbohydrates' => $macros['carbohydrates']['grams']
                ],
                'nutritionalSummary' => [
                    'tmb' => $nutritionalData['tmb'],
                    'get' => $nutritionalData['get'],
                    'targetCalories' => $nutritionalData['target_calories'],
                    'goal' => $nutritionalData['basic_data']['goal']
                ]
            ],
            'validation_data' => [
                'is_valid' => true,
                'method' => 'deterministic',
                'guaranteed_accurate' => true
            ],
            'generation_method' => 'deterministic_backup'
        ];
    }




    // LÍNEA ~1241 - Nuevos métodos auxiliares
private function isEggProduct($foodName): bool 
{
    $eggProducts = ['huevo entero', 'huevos', 'claras de huevo', 'claras pasteurizadas', 'huevo', 'clara'];
    $nameLower = strtolower($foodName);
    foreach ($eggProducts as $egg) {
        if (str_contains($nameLower, $egg)) {
            return true;
        }
    }
    return false;
}

private function addFoodMetadata(&$option, $isLowBudget = false) 
{
    $foodName = $option['name'] ?? '';
    $option['isEgg'] = $this->isEggProduct($foodName);
    $option['isHighBudget'] = $this->isFoodHighBudget($foodName);
    $option['isLowBudget'] = $this->isFoodLowBudget($foodName);
    $option['budgetAppropriate'] = $isLowBudget ? !$option['isHighBudget'] : !$option['isLowBudget'];
}



 
private function generateDeterministicMealOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget, $userWeight, $dietaryStyle): array
{
    // Ahora sí tenemos el dietaryStyle disponible
    $dietaryStyle = strtolower($dietaryStyle);
    $dietaryStyle = preg_replace('/[^\w\s]/u', '', $dietaryStyle);
    $dietaryStyle = trim($dietaryStyle);
    
    $options = [];
    
    // CASO 1: VEGANO
    if (str_contains($dietaryStyle, 'vegano')) {
        $options = $this->getVeganOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget);
    }
    // CASO 2: VEGETARIANO
    elseif (str_contains($dietaryStyle, 'vegetariano')) {
        $options = $this->getVegetarianOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget);
    }
    // CASO 3: KETO
    elseif (str_contains($dietaryStyle, 'keto')) {
        $options = $this->getKetoOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget);
    }
    // CASO 4: OMNÍVORO (default)
    else {
        $options = $this->getOmnivorousOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget);
    }
    
    // Agregar vegetales libres a todas las dietas
    $options['Vegetales'] = [
        'options' => [
            ['name' => 'Ensalada LIBRE', 'portion' => 'Sin restricción', 'calories' => 25, 'protein' => 2, 'fats' => 0, 'carbohydrates' => 5]
        ]
    ];
    
    return $options;
}

private function getKetoOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget): array
{
    $options = [];
    
    // Para KETO, los carbohidratos vienen principalmente de vegetales bajos en carbs
    $options['Carbohidratos'] = [
        'options' => [
            [
                'name' => 'Brócoli al vapor',
                'portion' => '200g',
                'calories' => 55,
                'protein' => 4,
                'fats' => 1,
                'carbohydrates' => 6 // Máximo 6g para mantener keto
            ],
            [
                'name' => 'Espinacas salteadas',
                'portion' => '150g',
                'calories' => 35,
                'protein' => 4,
                'fats' => 0,
                'carbohydrates' => 5
            ],
            [
                'name' => 'Coliflor',
                'portion' => '200g',
                'calories' => 50,
                'protein' => 4,
                'fats' => 0,
                'carbohydrates' => 6
            ]
        ]
    ];
    
    // Proteínas altas en grasa para keto
    if ($isLowBudget) { // AQUÍ ESTABA EL ERROR - faltaba el $
        $options['Proteínas'] = [
            'options' => [
                [
                    'name' => 'Huevos enteros',
                    'portion' => sprintf('%d unidades', round($targetProtein / 6)),
                    'calories' => round($targetProtein * 11.7),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.83),
                    'carbohydrates' => round($targetProtein * 0.08)
                ],
                [
                    'name' => 'Pollo muslo con piel',
                    'portion' => sprintf('%dg', round($targetProtein * 4)),
                    'calories' => round($targetProtein * 9.2),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.52),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Carne molida 80/20',
                    'portion' => sprintf('%dg', round($targetProtein * 3.8)),
                    'calories' => round($targetProtein * 10),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.6),
                    'carbohydrates' => 0
                ]
            ]
        ];
    } else {
        $options['Proteínas'] = [
            'options' => [
                [
                    'name' => 'Salmón',
                    'portion' => sprintf('%dg', round($targetProtein * 4)),
                    'calories' => round($targetProtein * 8.3),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.48),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Ribeye',
                    'portion' => sprintf('%dg', round($targetProtein * 3.5)),
                    'calories' => round($targetProtein * 10.5),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.7),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Pechuga de pato',
                    'portion' => sprintf('%dg', round($targetProtein * 3.7)),
                    'calories' => round($targetProtein * 12),
                    'protein' => $targetProtein,
                    'fats' => round($targetProtein * 0.8),
                    'carbohydrates' => 0
                ]
            ]
        ];
    }
    
    // Grasas aumentadas para keto
    $options['Grasas'] = [
        'options' => [
            [
                'name' => $isLowBudget ? 'Manteca de cerdo' : 'Aceite MCT', // AQUÍ TAMBIÉN SE CORRIGIÓ
                'portion' => sprintf('%d cucharadas', round($targetFats/14)),
                'calories' => round($targetFats * 9),
                'protein' => 0,
                'fats' => $targetFats,
                'carbohydrates' => 0
            ],
            [
                'name' => 'Mantequilla',
                'portion' => sprintf('%dg', round($targetFats * 1.25)),
                'calories' => round($targetFats * 9),
                'protein' => round($targetFats * 0.01),
                'fats' => $targetFats,
                'carbohydrates' => 0
            ],
            [
                'name' => 'Aguacate grande',
                'portion' => sprintf('%dg (1 unidad)', round($targetFats * 10)),
                'calories' => round($targetFats * 10.5),
                'protein' => round($targetFats * 0.2),
                'fats' => $targetFats,
                'carbohydrates' => round($targetFats * 0.5)
            ]
        ]
    ];
    
    return $options;
}



private function getOmnivorousOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget): array
{
    $options = [];
    
    if ($isLowBudget) {
        // PRESUPUESTO BAJO - OMNÍVORO
        if ($mealName === 'Desayuno') {
            // Calcular porciones dinámicamente para proteína objetivo
            $eggUnits = max(2, min(6, round($targetProtein / 6))); // 6g proteína por huevo
            $tunaGrams = round($targetProtein * 2.7); // ~37g proteína por 100g
            $chickenGrams = round($targetProtein * 3); // ~33g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Huevo entero',
                        'portion' => sprintf('%d unidades', $eggUnits),
                        'calories' => $eggUnits * 70,
                        'protein' => $eggUnits * 6,
                        'fats' => $eggUnits * 5,
                        'carbohydrates' => $eggUnits * 0.5
                    ],
                    [
                        'name' => 'Atún en lata',
                        'portion' => sprintf('%dg escurrido', $tunaGrams),
                        'calories' => round($tunaGrams * 1.8),
                        'protein' => round($targetProtein),
                        'fats' => round($tunaGrams * 0.025),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Pollo muslo',
                        'portion' => sprintf('%dg (peso en crudo)', $chickenGrams),
                        'calories' => round($chickenGrams * 2.3),
                        'protein' => round($targetProtein),
                        'fats' => round($chickenGrams * 0.12),
                        'carbohydrates' => 0
                    ]
                ]
            ];
            
        } elseif ($mealName === 'Almuerzo') {
            // 40% de los macros totales
            $chickenGrams = round($targetProtein * 3);
            $beefGrams = round($targetProtein * 2.85);
            $tunaGrams = round($targetProtein * 2.7);
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Pollo muslo',
                        'portion' => sprintf('%dg (peso en crudo)', $chickenGrams),
                        'calories' => round($chickenGrams * 2.3),
                        'protein' => round($targetProtein),
                        'fats' => round($chickenGrams * 0.12),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Carne molida',
                        'portion' => sprintf('%dg (peso en crudo)', $beefGrams),
                        'calories' => round($beefGrams * 2.85),
                        'protein' => round($targetProtein),
                        'fats' => round($beefGrams * 0.15),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Atún en lata',
                        'portion' => sprintf('%dg escurrido', $tunaGrams),
                        'calories' => round($tunaGrams * 1.8),
                        'protein' => round($targetProtein),
                        'fats' => round($tunaGrams * 0.025),
                        'carbohydrates' => 0
                    ]
                ]
            ];
            
        } else { // Cena
            // 30% de los macros totales
            $tunaGrams = round($targetProtein * 2.7);
            $chickenGrams = round($targetProtein * 3);
            $beefGrams = round($targetProtein * 2.85);
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Atún en lata',
                        'portion' => sprintf('%dg escurrido', $tunaGrams),
                        'calories' => round($tunaGrams * 1.8),
                        'protein' => round($targetProtein),
                        'fats' => round($tunaGrams * 0.025),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Pollo muslo',
                        'portion' => sprintf('%dg (peso en crudo)', $chickenGrams),
                        'calories' => round($chickenGrams * 2.3),
                        'protein' => round($targetProtein),
                        'fats' => round($chickenGrams * 0.12),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Carne molida',
                        'portion' => sprintf('%dg (peso en crudo)', $beefGrams),
                        'calories' => round($beefGrams * 2.85),
                        'protein' => round($targetProtein),
                        'fats' => round($beefGrams * 0.15),
                        'carbohydrates' => 0
                    ]
                ]
            ];
        }
        
        // Carbohidratos para presupuesto bajo - DINÁMICO
        $riceGrams = round($targetCarbs * 1.28); // 78g carbs por 100g
        $potatoGrams = round($targetCarbs * 5.5); // 18g carbs por 100g
        $oatsGrams = round($targetCarbs * 1.5); // 67g carbs por 100g
        
        $options['Carbohidratos'] = [
            'options' => [
                [
                    'name' => 'Arroz blanco',
                    'portion' => sprintf('%dg (peso en crudo)', $riceGrams),
                    'calories' => round($riceGrams * 3.5),
                    'protein' => round($riceGrams * 0.07),
                    'fats' => round($riceGrams * 0.01),
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Papa cocida',
                    'portion' => sprintf('%dg (peso cocido)', $potatoGrams),
                    'calories' => round($potatoGrams * 0.78),
                    'protein' => round($potatoGrams * 0.02),
                    'fats' => 0,
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Avena tradicional',
                    'portion' => sprintf('%dg (peso en seco)', $oatsGrams),
                    'calories' => round($oatsGrams * 3.75),
                    'protein' => round($oatsGrams * 0.13),
                    'fats' => round($oatsGrams * 0.07),
                    'carbohydrates' => round($targetCarbs)
                ]
            ]
        ];
        
        // Grasas para presupuesto bajo - DINÁMICO
        $oilMl = round($targetFats / 0.92); // 92g fat por 100ml
        $peanutGrams = round($targetFats * 2.13); // 47g fat por 100g
        $avocadoGrams = round($targetFats * 7.7); // 13g fat por 100g
        
        $options['Grasas'] = [
            'options' => [
                [
                    'name' => 'Aceite vegetal',
                    'portion' => sprintf('%d cucharadas (%dml)', round($oilMl/15), $oilMl),
                    'calories' => round($oilMl * 8),
                    'protein' => 0,
                    'fats' => round($targetFats),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Maní',
                    'portion' => sprintf('%dg', $peanutGrams),
                    'calories' => round($peanutGrams * 6),
                    'protein' => round($peanutGrams * 0.26),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($peanutGrams * 0.2)
                ],
                [
                    'name' => 'Aguacate',
                    'portion' => sprintf('%dg (1/%d unidad)', $avocadoGrams, max(2, round(200/$avocadoGrams))),
                    'calories' => round($avocadoGrams * 1.4),
                    'protein' => round($avocadoGrams * 0.02),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($avocadoGrams * 0.07)
                ]
            ]
        ];
        
    } else {
        // PRESUPUESTO ALTO - OMNÍVORO
        if ($mealName === 'Desayuno') {
            $eggWhitesMl = round($targetProtein * 8.3); // ~12g proteína por 100ml
            $greekYogurtGrams = round($targetProtein * 7.7); // ~13g proteína por 100g
            $wheyGrams = round($targetProtein * 1.25); // ~80g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Claras de huevo',
                        'portion' => sprintf('%dml (%d claras)', $eggWhitesMl, round($eggWhitesMl/30)),
                        'calories' => round($eggWhitesMl * 0.57),
                        'protein' => round($targetProtein),
                        'fats' => 0,
                        'carbohydrates' => round($eggWhitesMl * 0.013)
                    ],
                    [
                        'name' => 'Yogurt griego',
                        'portion' => sprintf('%dg', $greekYogurtGrams),
                        'calories' => round($greekYogurtGrams * 0.8),
                        'protein' => round($targetProtein),
                        'fats' => round($greekYogurtGrams * 0.025),
                        'carbohydrates' => round($greekYogurtGrams * 0.04)
                    ],
                    [
                        'name' => 'Proteína whey',
                        'portion' => sprintf('%dg (%d scoop)', $wheyGrams, max(1, round($wheyGrams/30))),
                        'calories' => round($wheyGrams * 4),
                        'protein' => round($targetProtein),
                        'fats' => round($wheyGrams * 0.03),
                        'carbohydrates' => round($wheyGrams * 0.1)
                    ]
                ]
            ];
            
        } elseif ($mealName === 'Almuerzo') {
            $chickenBreastGrams = round($targetProtein * 3.3); // ~31g proteína por 100g
            $salmonGrams = round($targetProtein * 4); // ~25g proteína por 100g
            $beefGrams = round($targetProtein * 3.3); // ~30g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Pechuga de pollo',
                        'portion' => sprintf('%dg (peso en crudo)', $chickenBreastGrams),
                        'calories' => round($chickenBreastGrams * 1.65),
                        'protein' => round($targetProtein),
                        'fats' => round($chickenBreastGrams * 0.036),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Salmón',
                        'portion' => sprintf('%dg (peso en crudo)', $salmonGrams),
                        'calories' => round($salmonGrams * 2.08),
                        'protein' => round($targetProtein),
                        'fats' => round($salmonGrams * 0.12),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Lomo de res',
                        'portion' => sprintf('%dg (peso en crudo)', $beefGrams),
                        'calories' => round($beefGrams * 2.13),
                        'protein' => round($targetProtein),
                        'fats' => round($beefGrams * 0.10),
                        'carbohydrates' => 0
                    ]
                ]
            ];
            
        } else { // Cena
            $salmonGrams = round($targetProtein * 4);
            $chickenBreastGrams = round($targetProtein * 3.3);
            $tunaFreshGrams = round($targetProtein * 2.4); // ~42g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Salmón',
                        'portion' => sprintf('%dg (peso en crudo)', $salmonGrams),
                        'calories' => round($salmonGrams * 2.08),
                        'protein' => round($targetProtein),
                        'fats' => round($salmonGrams * 0.12),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Pechuga de pollo',
                        'portion' => sprintf('%dg (peso en crudo)', $chickenBreastGrams),
                        'calories' => round($chickenBreastGrams * 1.65),
                        'protein' => round($targetProtein),
                        'fats' => round($chickenBreastGrams * 0.036),
                        'carbohydrates' => 0
                    ],
                    [
                        'name' => 'Atún fresco',
                        'portion' => sprintf('%dg (peso en crudo)', $tunaFreshGrams),
                        'calories' => round($tunaFreshGrams * 1.85),
                        'protein' => round($targetProtein),
                        'fats' => round($tunaFreshGrams * 0.01),
                        'carbohydrates' => 0
                    ]
                ]
            ];
        }
        
        // Carbohidratos para presupuesto alto - DINÁMICO
        $quinoaGrams = round($targetCarbs * 1.56); // 64g carbs por 100g
        $sweetPotatoGrams = round($targetCarbs * 5); // 20g carbs por 100g
        $brownRiceGrams = round($targetCarbs * 1.3); // 77g carbs por 100g
        
        $options['Carbohidratos'] = [
            'options' => [
                [
                    'name' => 'Quinua',
                    'portion' => sprintf('%dg (peso en crudo)', $quinoaGrams),
                    'calories' => round($quinoaGrams * 3.65),
                    'protein' => round($quinoaGrams * 0.14),
                    'fats' => round($quinoaGrams * 0.06),
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Camote',
                    'portion' => sprintf('%dg (peso cocido)', $sweetPotatoGrams),
                    'calories' => round($sweetPotatoGrams * 0.86),
                    'protein' => round($sweetPotatoGrams * 0.016),
                    'fats' => 0,
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Arroz integral',
                    'portion' => sprintf('%dg (peso en crudo)', $brownRiceGrams),
                    'calories' => round($brownRiceGrams * 3.7),
                    'protein' => round($brownRiceGrams * 0.075),
                    'fats' => round($brownRiceGrams * 0.025),
                    'carbohydrates' => round($targetCarbs)
                ]
            ]
        ];
        
        // Grasas para presupuesto alto - DINÁMICO
        $oliveOilMl = round($targetFats); // 100g fat por 100ml
        $almondsGrams = round($targetFats * 2); // 50g fat por 100g
        $avocadoHassGrams = round($targetFats * 5.3); // 19g fat por 100g
        
        $options['Grasas'] = [
            'options' => [
                [
                    'name' => 'Aceite de oliva extra virgen',
                    'portion' => sprintf('%d cucharadas (%dml)', round($oliveOilMl/15), $oliveOilMl),
                    'calories' => round($oliveOilMl * 9),
                    'protein' => 0,
                    'fats' => round($targetFats),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Almendras',
                    'portion' => sprintf('%dg', $almondsGrams),
                    'calories' => round($almondsGrams * 5.75),
                    'protein' => round($almondsGrams * 0.21),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($almondsGrams * 0.1)
                ],
                [
                    'name' => 'Aguacate hass',
                    'portion' => sprintf('%dg (1/%d unidad)', $avocadoHassGrams, max(2, round(200/$avocadoHassGrams))),
                    'calories' => round($avocadoHassGrams * 2),
                    'protein' => round($avocadoHassGrams * 0.02),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($avocadoHassGrams * 0.09)
                ]
            ]
        ];
    }
    

foreach ($options as $category => &$categoryData) {
    if (isset($categoryData['options'])) {
        foreach ($categoryData['options'] as &$option) {
            $this->addFoodMetadata($option, $isLowBudget);
        }
    }
}

    return $options;
}



/**
 * OPCIONES PARA VEGETARIANOS - Completamente dinámico
 */
private function getVegetarianOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget): array
{
    $options = [];
    
    if ($mealName === 'Desayuno') {
        // Proteínas vegetarianas para desayuno
        $eggUnits = max(2, min(8, round($targetProtein / 6))); // 6g proteína por huevo
$yogurtGrams = round($targetProtein * ($isLowBudget ? 12.5 : 7.7));
        $cheeseGrams = round($targetProtein * 4.5); // ~22g proteína por 100g
        
        $options['Proteínas'] = [
            'options' => [
                [
                    'name' => 'Huevos enteros',
                    'portion' => sprintf('%d unidades', $eggUnits),
                    'calories' => $eggUnits * 70,
                    'protein' => $eggUnits * 6,
                    'fats' => $eggUnits * 5,
                    'carbohydrates' => $eggUnits * 0.5
                ],
                [
                    'name' => $isLowBudget ? 'Yogurt natural' : 'Yogurt griego',
                    'portion' => sprintf('%dg', $yogurtGrams),
                    'calories' => round($yogurtGrams * ($isLowBudget ? 0.61 : 0.9)),
                    'protein' => round($targetProtein),
                    'fats' => round($yogurtGrams * ($isLowBudget ? 0.033 : 0.05)),
                    'carbohydrates' => round($yogurtGrams * ($isLowBudget ? 0.047 : 0.04))
                ],
                [
                    'name' => $isLowBudget ? 'Queso fresco' : 'Queso cottage',
                    'portion' => sprintf('%dg', $cheeseGrams),
                    'calories' => round($cheeseGrams * ($isLowBudget ? 1.85 : 0.98)),
                    'protein' => round($targetProtein),
                    'fats' => round($cheeseGrams * ($isLowBudget ? 0.10 : 0.04)),
                    'carbohydrates' => round($cheeseGrams * ($isLowBudget ? 0.04 : 0.03))
                ]
            ]
        ];
        
    } elseif ($mealName === 'Almuerzo') {
        // Proteínas vegetarianas para almuerzo - porciones más grandes
        if ($isLowBudget) {
            $lentejasGrams = round($targetProtein * 11.1); // 9g proteína por 100g cocidas
            $frijolesGrams = round($targetProtein * 11.5); // 8.7g proteína por 100g cocidos
            $tofuGrams = round($targetProtein * 12.5); // 8g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Lentejas cocidas',
                        'portion' => sprintf('%dg', $lentejasGrams),
                        'calories' => round($lentejasGrams * 1.16),
                        'protein' => round($targetProtein),
                        'fats' => round($lentejasGrams * 0.004),
                        'carbohydrates' => round($lentejasGrams * 0.20)
                    ],
                    [
                        'name' => 'Frijoles negros cocidos',
                        'portion' => sprintf('%dg', $frijolesGrams),
                        'calories' => round($frijolesGrams * 1.32),
                        'protein' => round($targetProtein),
                        'fats' => round($frijolesGrams * 0.005),
                        'carbohydrates' => round($frijolesGrams * 0.24)
                    ],
                    [
                        'name' => 'Tofu firme',
                        'portion' => sprintf('%dg', $tofuGrams),
                        'calories' => round($tofuGrams * 1.44),
                        'protein' => round($targetProtein),
                        'fats' => round($tofuGrams * 0.09),
                        'carbohydrates' => round($tofuGrams * 0.03)
                    ]
                ]
            ];
        } else {
            $tempehGrams = round($targetProtein * 5.3); // 19g proteína por 100g
            $seitanGrams = round($targetProtein * 4); // 25g proteína por 100g
            $proteinCheeseGrams = round($targetProtein * 3.8); // 26g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Tempeh',
                        'portion' => sprintf('%dg', $tempehGrams),
                        'calories' => round($tempehGrams * 1.93),
                        'protein' => round($targetProtein),
                        'fats' => round($tempehGrams * 0.11),
                        'carbohydrates' => round($tempehGrams * 0.09)
                    ],
                    [
                        'name' => 'Seitán',
                        'portion' => sprintf('%dg', $seitanGrams),
                        'calories' => round($seitanGrams * 3.7),
                        'protein' => round($targetProtein),
                        'fats' => round($seitanGrams * 0.02),
                        'carbohydrates' => round($seitanGrams * 0.14)
                    ],
                    [
                        'name' => 'Queso panela a la plancha',
                        'portion' => sprintf('%dg', $proteinCheeseGrams),
                        'calories' => round($proteinCheeseGrams * 3.2),
                        'protein' => round($targetProtein),
                        'fats' => round($proteinCheeseGrams * 0.22),
                        'carbohydrates' => round($proteinCheeseGrams * 0.03)
                    ]
                ]
            ];
        }
        
    } else { // Cena
        // Proteínas vegetarianas para cena
        if ($isLowBudget) {
            $eggUnits = max(2, min(6, round($targetProtein / 6)));
            $garbanzosGrams = round($targetProtein * 12.2); // 8.2g proteína por 100g cocidos
            $quesoGrams = round($targetProtein * 5.5); // 18g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Huevos revueltos',
                        'portion' => sprintf('%d unidades', $eggUnits),
                        'calories' => $eggUnits * 70,
                        'protein' => $eggUnits * 6,
                        'fats' => $eggUnits * 5,
                        'carbohydrates' => $eggUnits * 0.5
                    ],
                    [
                        'name' => 'Garbanzos cocidos',
                        'portion' => sprintf('%dg', $garbanzosGrams),
                        'calories' => round($garbanzosGrams * 1.64),
                        'protein' => round($targetProtein),
                        'fats' => round($garbanzosGrams * 0.03),
                        'carbohydrates' => round($garbanzosGrams * 0.27)
                    ],
                    [
                        'name' => 'Queso Oaxaca',
                        'portion' => sprintf('%dg', $quesoGrams),
                        'calories' => round($quesoGrams * 3.5),
                        'protein' => round($targetProtein),
                        'fats' => round($quesoGrams * 0.28),
                        'carbohydrates' => round($quesoGrams * 0.02)
                    ]
                ]
            ];
        } else {
            $greekYogurtGrams = round($targetProtein * 5); // 20g proteína por 100g con granola
            $proteinPowderGrams = round($targetProtein * 1.25); // 80g proteína por 100g
            $ricottaGrams = round($targetProtein * 9); // 11g proteína por 100g
            
            $options['Proteínas'] = [
                'options' => [
                    [
                        'name' => 'Yogurt griego con granola proteica',
                        'portion' => sprintf('%dg yogurt + 30g granola', $greekYogurtGrams),
                        'calories' => round($greekYogurtGrams * 0.9 + 150),
                        'protein' => round($targetProtein),
                        'fats' => round($greekYogurtGrams * 0.05 + 5),
                        'carbohydrates' => round($greekYogurtGrams * 0.04 + 20)
                    ],
                    [
                        'name' => 'Proteína vegetal en polvo',
                        'portion' => sprintf('%dg (%d scoops)', $proteinPowderGrams, max(1, round($proteinPowderGrams/30))),
                        'calories' => round($proteinPowderGrams * 3.8),
                        'protein' => round($targetProtein),
                        'fats' => round($proteinPowderGrams * 0.02),
                        'carbohydrates' => round($proteinPowderGrams * 0.08)
                    ],
                    [
                        'name' => 'Ricotta con hierbas',
                        'portion' => sprintf('%dg', $ricottaGrams),
                        'calories' => round($ricottaGrams * 1.74),
                        'protein' => round($targetProtein),
                        'fats' => round($ricottaGrams * 0.13),
                        'carbohydrates' => round($ricottaGrams * 0.03)
                    ]
                ]
            ];
        }
    }
    
    // Carbohidratos vegetarianos - igual que omnívoro pero con opciones adicionales
    if ($isLowBudget) {
        $riceGrams = round($targetCarbs * 1.28);
        $pastaGrams = round($targetCarbs * 1.33);
        $tortillasUnits = round($targetCarbs / 15); // ~15g carbs por tortilla
        
        $options['Carbohidratos'] = [
            'options' => [
                [
                    'name' => 'Arroz blanco',
                    'portion' => sprintf('%dg (peso en crudo)', $riceGrams),
                    'calories' => round($riceGrams * 3.5),
                    'protein' => round($riceGrams * 0.07),
                    'fats' => round($riceGrams * 0.01),
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Pasta integral',
                    'portion' => sprintf('%dg (peso en crudo)', $pastaGrams),
                    'calories' => round($pastaGrams * 3.5),
                    'protein' => round($pastaGrams * 0.13),
                    'fats' => round($pastaGrams * 0.02),
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Tortillas de maíz',
                    'portion' => sprintf('%d tortillas', $tortillasUnits),
                    'calories' => $tortillasUnits * 60,
                    'protein' => $tortillasUnits * 1.5,
                    'fats' => $tortillasUnits * 0.8,
                    'carbohydrates' => $tortillasUnits * 15
                ]
            ]
        ];
    } else {
        $quinoaGrams = round($targetCarbs * 1.56);
        $sweetPotatoGrams = round($targetCarbs * 5);
        $wholeWheatBreadSlices = round($targetCarbs / 15); // ~15g carbs por rebanada
        
        $options['Carbohidratos'] = [
            'options' => [
                [
                    'name' => 'Quinua',
                    'portion' => sprintf('%dg (peso en crudo)', $quinoaGrams),
                    'calories' => round($quinoaGrams * 3.65),
                    'protein' => round($quinoaGrams * 0.14),
                    'fats' => round($quinoaGrams * 0.06),
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Camote al horno',
                    'portion' => sprintf('%dg', $sweetPotatoGrams),
                    'calories' => round($sweetPotatoGrams * 0.86),
                    'protein' => round($sweetPotatoGrams * 0.016),
                    'fats' => 0,
                    'carbohydrates' => round($targetCarbs)
                ],
                [
                    'name' => 'Pan integral artesanal',
                    'portion' => sprintf('%d rebanadas', $wholeWheatBreadSlices),
                    'calories' => $wholeWheatBreadSlices * 80,
                    'protein' => $wholeWheatBreadSlices * 4,
                    'fats' => $wholeWheatBreadSlices * 1.5,
                    'carbohydrates' => $wholeWheatBreadSlices * 15
                ]
            ]
        ];
    }
    
    // Grasas vegetarianas
    if ($isLowBudget) {
        $oilMl = round($targetFats / 0.92);
        $peanutButterGrams = round($targetFats * 2); // 50g fat por 100g
        $sunflowerSeedsGrams = round($targetFats * 1.96); // 51g fat por 100g
        
        $options['Grasas'] = [
            'options' => [
                [
                    'name' => 'Aceite vegetal',
                    'portion' => sprintf('%d cucharadas (%dml)', round($oilMl/15), $oilMl),
                    'calories' => round($oilMl * 8),
                    'protein' => 0,
                    'fats' => round($targetFats),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Crema de cacahuate',
                    'portion' => sprintf('%dg (%d cucharadas)', $peanutButterGrams, round($peanutButterGrams/16)),
                    'calories' => round($peanutButterGrams * 5.88),
                    'protein' => round($peanutButterGrams * 0.25),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($peanutButterGrams * 0.20)
                ],
                [
                    'name' => 'Semillas de girasol',
                    'portion' => sprintf('%dg', $sunflowerSeedsGrams),
                    'calories' => round($sunflowerSeedsGrams * 5.84),
                    'protein' => round($sunflowerSeedsGrams * 0.21),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($sunflowerSeedsGrams * 0.20)
                ]
            ]
        ];
    } else {
        $oliveOilMl = round($targetFats);
        $walnutsGrams = round($targetFats * 1.54); // 65g fat por 100g
        $chiaGrams = round($targetFats * 3.23); // 31g fat por 100g
        
        $options['Grasas'] = [
            'options' => [
                [
                    'name' => 'Aceite de oliva extra virgen',
                    'portion' => sprintf('%d cucharadas (%dml)', round($oliveOilMl/15), $oliveOilMl),
                    'calories' => round($oliveOilMl * 9),
                    'protein' => 0,
                    'fats' => round($targetFats),
                    'carbohydrates' => 0
                ],
                [
                    'name' => 'Nueces',
                    'portion' => sprintf('%dg', $walnutsGrams),
                    'calories' => round($walnutsGrams * 6.54),
                    'protein' => round($walnutsGrams * 0.15),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($walnutsGrams * 0.14)
                ],
                [
                    'name' => 'Semillas de chía',
                    'portion' => sprintf('%dg', $chiaGrams),
                    'calories' => round($chiaGrams * 4.86),
                    'protein' => round($chiaGrams * 0.17),
                    'fats' => round($targetFats),
                    'carbohydrates' => round($chiaGrams * 0.42)
                ]
            ]
        ];
    }
    

    foreach ($options as $category => &$categoryData) {
    if (isset($categoryData['options'])) {
        foreach ($categoryData['options'] as &$option) {
            $this->addFoodMetadata($option, $isLowBudget);
        }
    }
}

    return $options;
}

private function getVeganOptions($mealName, $targetProtein, $targetCarbs, $targetFats, $isLowBudget): array
{
    $options = [];
    
    if ($mealName === 'Desayuno') {
        // Proteínas veganas
        $tofuGrams = round($targetProtein * 12.5); // 8g proteína por 100g
        $lentejasGrams = round($targetProtein * 11); // 9g proteína por 100g
        $garbanzosGrams = round($targetProtein * 12); // 8g proteína por 100g
        
        $options['Proteínas'] = [
            'options' => [
                [
                    'name' => 'Tofu firme',
                    'portion' => sprintf('%dg', $tofuGrams),
                    'calories' => round($tofuGrams * 1.44),
                    'protein' => round($targetProtein),
                    'fats' => round($tofuGrams * 0.09),
                    'carbohydrates' => round($tofuGrams * 0.03)
                ],
                [
                    'name' => 'Lentejas cocidas',
                    'portion' => sprintf('%dg', $lentejasGrams),
                    'calories' => round($lentejasGrams * 1.16),
                    'protein' => round($targetProtein),
                    'fats' => round($lentejasGrams * 0.004),
                    'carbohydrates' => round($lentejasGrams * 0.2)
                ],
                [
                    'name' => 'Garbanzos cocidos',
                    'portion' => sprintf('%dg', $garbanzosGrams),
                    'calories' => round($garbanzosGrams * 1.64),
                    'protein' => round($targetProtein),
                    'fats' => round($garbanzosGrams * 0.03),
                    'carbohydrates' => round($garbanzosGrams * 0.27)
                ]
            ]
        ];
        
        // Carbohidratos veganos
        $options['Carbohidratos'] = [
            'options' => [
                [
                    'name' => 'Avena tradicional',
                    'portion' => sprintf('%dg', round($targetCarbs * 1.5)),
                    'calories' => round($targetCarbs * 5.6),
                    'protein' => round($targetCarbs * 0.2),
                    'fats' => round($targetCarbs * 0.1),
                    'carbohydrates' => $targetCarbs
                ],
                [
                    'name' => 'Pan integral',
                    'portion' => sprintf('%dg', round($targetCarbs * 2)),
                    'calories' => round($targetCarbs * 5),
                    'protein' => round($targetCarbs * 0.18),
                    'fats' => round($targetCarbs * 0.06),
                    'carbohydrates' => $targetCarbs
                ],
                [
                    'name' => 'Quinua cocida',
                    'portion' => sprintf('%dg', round($targetCarbs * 4.5)),
                    'calories' => round($targetCarbs * 5.4),
                    'protein' => round($targetCarbs * 0.2),
                    'fats' => round($targetCarbs * 0.08),
                    'carbohydrates' => $targetCarbs
                ]
            ]
        ];
    } elseif ($mealName === 'Almuerzo' || $mealName === 'Cena') {
        // Similar structure but different portions
        $seitanGrams = round($targetProtein * 4); // 25g proteína por 100g
        $tempehGrams = round($targetProtein * 5.3); // 19g proteína por 100g
        
        $options['Proteínas'] = [
            'options' => [
                [
                    'name' => 'Seitán',
                    'portion' => sprintf('%dg', $seitanGrams),
                    'calories' => round($seitanGrams * 3.7),
                    'protein' => round($targetProtein),
                    'fats' => round($seitanGrams * 0.02),
                    'carbohydrates' => round($seitanGrams * 0.14)
                ],
                [
                    'name' => 'Tempeh',
                    'portion' => sprintf('%dg', $tempehGrams),
                    'calories' => round($tempehGrams * 1.93),
                    'protein' => round($targetProtein),
                    'fats' => round($tempehGrams * 0.11),
                    'carbohydrates' => round($tempehGrams * 0.09)
                ],
                [
                    'name' => 'Hamburguesa de lentejas',
                    'portion' => sprintf('%dg (2 unidades)', round($targetProtein * 6)),
                    'calories' => round($targetProtein * 7),
                    'protein' => round($targetProtein),
                    'fats' => round($targetProtein * 0.3),
                    'carbohydrates' => round($targetProtein * 1.5)
                ]
            ]
        ];
    }
    
    // Grasas veganas (para todas las comidas)
    $options['Grasas'] = [
        'options' => [
            [
                'name' => 'Aceite de oliva',
                'portion' => sprintf('%d cucharadas', round($targetFats/15)),
                'calories' => round($targetFats * 9),
                'protein' => 0,
                'fats' => $targetFats,
                'carbohydrates' => 0
            ],
            [
                'name' => 'Aguacate',
                'portion' => sprintf('%dg', round($targetFats * 6.5)),
                'calories' => round($targetFats * 10),
                'protein' => round($targetFats * 0.13),
                'fats' => $targetFats,
                'carbohydrates' => round($targetFats * 0.5)
            ],
            [
'name' => $isLowBudget ? 'Maní' : 'Almendras',
                'portion' => sprintf('%dg', round($targetFats * 2)),
                'calories' => round($targetFats * 11.5),
                'protein' => round($targetFats * 0.4),
                'fats' => $targetFats,
                'carbohydrates' => round($targetFats * 0.4)
            ]
        ]
    ];
    
    foreach ($options as $category => &$categoryData) {
    if (isset($categoryData['options'])) {
        foreach ($categoryData['options'] as &$option) {
            $this->addFoodMetadata($option, $isLowBudget);
        }
    }
}



    return $options;
}



    private function getDetailedBudgetInstructions($budget, $country): string
    {
        $budgetLevel = strtolower($budget);
        
        if (str_contains($budgetLevel, 'bajo')) {
            $baseInstructions = "**PRESUPUESTO BAJO - ALIMENTOS OBLIGATORIOS:**
            
            **PROTEÍNAS ECONÓMICAS:**
            - Huevo entero (siempre disponible y económico)
            - Carne molida (en lugar de cortes premium)
            - Pollo (muslos/encuentros, NO pechuga)
            - Pescado económico local (bonito, jurel, caballa - NO salmón)
            - Atún en lata (opción práctica)
            - Legumbres: lentejas, frijoles, garbanzos
            
            **CARBOHIDRATOS BÁSICOS:**
            - Arroz blanco (base alimentaria)
            - Fideos/pasta común (opción económica)
            - Papa (tubérculo básico)
            - Camote (alternativa nutritiva)
            - Avena tradicional (no instantánea)
            - Pan de molde común
            
            **GRASAS ACCESIBLES:**
            - Aceite vegetal común (NO aceite de oliva extra virgen)
            - Maní (en lugar de almendras)
            - Aguacate pequeño (cuando esté en temporada)
            
            **PROHIBIDO EN PRESUPUESTO BAJO:**
            Salmón, lomo de res, pechuga de pollo, almendras, nueces, frutos rojos, quinua importada, yogur griego, quesos premium, aceite de oliva extra virgen, proteína en polvo";
            
        } else {
            $baseInstructions = "**PRESUPUESTO ALTO - ALIMENTOS PREMIUM:**
            
            **PROTEÍNAS PREMIUM:**
            - Salmón fresco (en lugar de pescado básico)
            - Lomo de res (en lugar de carne molida)
            - Pechuga de pollo (corte premium)
            - Pescados finos (corvina, lenguado, róbalo)
            - Proteína en polvo (suplementación)
            - Yogur griego (alta proteína)
            - Quesos finos y madurados
            
            **CARBOHIDRATOS GOURMET:**
            - Quinua (superfood andino)
            - Avena orgánica
            - Arroz integral/basmati
            - Camote morado
            - Pan artesanal/integral premium
            - Pasta integral o de legumbres
            
            **GRASAS PREMIUM:**
            - Aceite de oliva extra virgen
            - Almendras, nueces, pistachos
            - Aguacate hass grande
            - Aceite de coco orgánico
            - Semillas premium (chía, linaza)
            
            **FRUTAS GOURMET:**
            - Frutos rojos (arándanos, frambuesas)
            - Frutas importadas de calidad
            - Frutas orgánicas
            - Superfoods (açaí, goji)";
        }
        
        return $baseInstructions;
    }

    private function getDetailedDietaryInstructions($dietaryStyle): string
    {
        $style = strtolower($dietaryStyle);
        
        if ($style === 'vegano') {
            return "**OBLIGATORIO VEGANO:** 
            - Solo alimentos de origen vegetal
            - Proteínas: legumbres, tofu, seitán, quinua, frutos secos, semillas
            - B12 y hierro: considerar suplementación
            - Combinar proteínas para aminoácidos completos";
        } elseif ($style === 'vegetariano') {
            return "**OBLIGATORIO VEGETARIANO:** 
            - Sin carne ni pescado
            - Incluye: huevos, lácteos, legumbres, frutos secos
            - Asegurar hierro y B12 suficientes";
        } elseif (str_contains($style, 'keto')) {
            return "**OBLIGATORIO KETO:** 
            - Máximo 50g carbohidratos netos totales
            - 70% grasas, 25% proteínas, 5% carbohidratos
            - Priorizar: aguacate, aceites, frutos secos, carnes, pescados grasos
            - EVITAR: granos, frutas altas en azúcar, tubérculos";
        }
        
        return "**OMNÍVORO:** Todos los grupos de alimentos permitidos, priorizando variedad y calidad nutricional.";
    }

    private function getCommunicationStyleInstructions($communicationStyle, $preferredName): string
    {
        $style = strtolower($communicationStyle);
        
        if (str_contains($style, 'motivadora')) {
            return "**COMUNICACIÓN MOTIVADORA:** 
            - Usa frases empoderadoras y desafiantes
            - Recuerda sus logros y capacidades
            - Enfócate en el progreso y superación personal
            - Tono enérgico: '¡{$preferredName}, vas a lograr esto!', '¡Tu fuerza te llevará al éxito!'";
        } elseif (str_contains($style, 'cercana')) {
            return "**COMUNICACIÓN CERCANA:** 
            - Tono amigable y comprensivo
            - Usa su nombre frecuentemente
            - Comparte consejos como un amigo
            - Tono cálido: 'Hola {$preferredName}', 'Sabemos que puedes', 'Estamos aquí contigo'";
        } elseif (str_contains($style, 'directa')) {
            return "**COMUNICACIÓN DIRECTA:** 
            - Información clara y concisa
            - Sin rodeos ni frases suaves
            - Datos específicos y acciones concretas
            - Tono directo: '{$preferredName}, esto es lo que necesitas hacer', 'Plan claro y simple'";
        }
        
        return "**COMUNICACIÓN ADAPTATIVA:** Mezcla todos los estilos según el contexto, siendo versátil.";
    }

    private function getCountrySpecificFoods($country, $budget): string
    {
        $countryLower = strtolower($country);
        $budgetLower = strtolower($budget);
        
        $budgetFoodMatrix = [
            'bajo' => [
                'proteinas' => 'Huevo entero, Atún en lata, Pechuga de pollo, Queso fresco, Pescado bonito, Carne molida común',
                'carbohidratos' => 'Quinua, Lentejas, Frejoles, Camote, Papa, Arroz blanco, Fideos, Avena, Tortilla de maíz, Pan integral',
                'grasas' => 'Maní, Mantequilla de maní casera, Semillas de ajonjolí, Aceitunas, Aceite de oliva'
            ],
            'alto' => [
                'proteinas' => 'Claras de huevo pasteurizadas, Proteína en polvo (whey), Yogurt griego alto en proteínas, Pechuga de pollo premium, Pechuga de pavo, Carne de res magra, Salmón fresco, Lenguado fresco',
                'carbohidratos' => 'Quinua, Lentejas, Frejoles, Camote, Papa, Arroz blanco, Fideos, Avena, Tortilla de maíz, Pan integral',
                'grasas' => 'Aceite de oliva extra virgen, Aceite de palta, Palta (aguacate Hass), Almendras, Nueces, Pistachos, Pecanas, Semillas de chía orgánicas, Linaza orgánica'
            ]
        ];

        $budgetLevel = str_contains($budgetLower, 'bajo') ? 'bajo' : 'alto';
        $foods = $budgetFoodMatrix[$budgetLevel];
        
        return "**INGREDIENTES ESPECÍFICOS DE " . strtoupper($country) . ":**\nProteínas: {$foods['proteinas']}\nCarbohidratos: {$foods['carbohidratos']}\nGrasas: {$foods['grasas']}";
    }

     private function generatePersonalizedRecipes(array $planData, $profile, $nutritionalData): array
{
    $mealsToSearch = array_keys($planData['nutritionPlan']['meals'] ?? []);
    if (empty($mealsToSearch)) {
        return $planData;
    }
    
    // Extraer y estructurar TODOS los datos del perfil para máxima personalización
    $profileData = [
        'name' => $nutritionalData['basic_data']['preferences']['preferred_name'] ?? $nutritionalData['basic_data']['preferences']['name'] ?? 'Usuario',
        'goal' => $nutritionalData['basic_data']['goal'] ?? '',
        'weight' => $nutritionalData['basic_data']['weight'] ?? 0,
        'height' => $nutritionalData['basic_data']['height'] ?? 0,
        'age' => $nutritionalData['basic_data']['age'] ?? 0,
        'sex' => $nutritionalData['basic_data']['sex'] ?? '',
        'dietary_style' => $nutritionalData['basic_data']['preferences']['dietary_style'] ?? 'Omnívoro',
        'budget' => $nutritionalData['basic_data']['preferences']['budget'] ?? '',
        'disliked_foods' => $nutritionalData['basic_data']['preferences']['disliked_foods'] ?? '',
        'allergies' => $nutritionalData['basic_data']['health_status']['allergies'] ?? '',
        'has_allergies' => $nutritionalData['basic_data']['health_status']['has_allergies'] ?? false,
        'medical_condition' => $nutritionalData['basic_data']['health_status']['medical_condition'] ?? '',
        'has_medical_condition' => $nutritionalData['basic_data']['health_status']['has_medical_condition'] ?? false,
        'country' => $nutritionalData['basic_data']['country'] ?? 'Mexico',
        'sports' => $nutritionalData['basic_data']['sports_data']['sports'] ?? [],
        'training_frequency' => $nutritionalData['basic_data']['sports_data']['training_frequency'] ?? '',
        'weekly_activity' => $nutritionalData['basic_data']['activity_level'] ?? '',
        'communication_style' => $nutritionalData['basic_data']['preferences']['communication_style'] ?? '',
        'eats_out' => $nutritionalData['basic_data']['preferences']['eats_out'] ?? '',
        'meal_count' => $nutritionalData['basic_data']['preferences']['meal_count'] ?? '',
        'diet_difficulties' => $nutritionalData['basic_data']['emotional_profile']['diet_difficulties'] ?? [],
        'diet_motivations' => $nutritionalData['basic_data']['emotional_profile']['diet_motivations'] ?? [],
        'meal_times' => $nutritionalData['basic_data']['meal_times'] ?? [
            'breakfast_time' => '07:00',
            'lunch_time' => '13:00', 
            'dinner_time' => '20:00'
        ],
        'bmi' => $nutritionalData['basic_data']['anthropometric_data']['bmi'] ?? 0,
        'weight_status' => $nutritionalData['basic_data']['anthropometric_data']['weight_status'] ?? '',
        'target_calories' => $nutritionalData['target_calories'] ?? 0,
        'target_protein' => $nutritionalData['macros']['protein']['grams'] ?? 0,
        'target_carbs' => $nutritionalData['macros']['carbohydrates']['grams'] ?? 0,
        'target_fats' => $nutritionalData['macros']['fats']['grams'] ?? 0
    ];
    
    foreach ($mealsToSearch as $mealName) {
        if (isset($planData['nutritionPlan']['meals'][$mealName])) {
            $mealComponents = $planData['nutritionPlan']['meals'][$mealName];
            
            // Calcular macros específicos para esta comida
            $mealPercentages = [
                'Desayuno' => 0.30,
                'Almuerzo' => 0.40,
                'Cena' => 0.30
            ];
            
            $mealPercentage = $mealPercentages[$mealName] ?? 0.33;
            $profileData['meal_target_protein'] = round($profileData['target_protein'] * $mealPercentage);
            $profileData['meal_target_carbs'] = round($profileData['target_carbs'] * $mealPercentage);
            $profileData['meal_target_fats'] = round($profileData['target_fats'] * $mealPercentage);
            $profileData['meal_target_calories'] = round($profileData['target_calories'] * $mealPercentage);
            
            // Generar recetas ultra-personalizadas
            $recipes = $this->generateUltraPersonalizedRecipesForMeal(
                $mealComponents, 
                $profileData,
                $nutritionalData,
                $mealName
            );
            
            if (!empty($recipes)) {
                // Validar cada receta antes de incluirla
                $validRecipes = [];
                foreach ($recipes as $recipe) {
                    if ($this->validateRecipeIngredients($recipe, $profileData)) {
                        $validRecipes[] = $recipe;
                    } else {
                        Log::warning("Receta rechazada por contener ingredientes prohibidos", [
                            'recipe' => $recipe['name'] ?? 'Sin nombre',
                            'meal' => $mealName
                        ]);
                    }
                }
                
                if (!empty($validRecipes)) {
                    $planData['nutritionPlan']['meals'][$mealName]['suggested_recipes'] = $validRecipes;
                    $planData['nutritionPlan']['meals'][$mealName]['meal_timing'] = $this->getMealTiming($mealName, $profileData['meal_times']);
                    $planData['nutritionPlan']['meals'][$mealName]['personalized_tips'] = $this->getMealSpecificTips($mealName, $profileData);
                    
                    Log::info(count($validRecipes) . " recetas ultra-personalizadas validadas para {$mealName}.");
                }
            }
        }
    }
    
    return $planData;
}


private function generateUltraPersonalizedRecipesForMeal(array $mealComponents, array $profileData, $nutritionalData, $mealName): ?array
{
    // Extraer opciones de alimentos disponibles de los componentes de la comida
    $proteinOptions = [];
    $carbOptions = [];
    $fatOptions = [];
    
    if (isset($mealComponents['Proteínas']['options'])) {
        $proteinOptions = array_map(fn($opt) => $opt['name'] . ' (' . $opt['portion'] . ')', $mealComponents['Proteínas']['options']);
    }
    if (isset($mealComponents['Carbohidratos']['options'])) {
        $carbOptions = array_map(fn($opt) => $opt['name'] . ' (' . $opt['portion'] . ')', $mealComponents['Carbohidratos']['options']);
    }
    if (isset($mealComponents['Grasas']['options'])) {
        $fatOptions = array_map(fn($opt) => $opt['name'] . ' (' . $opt['portion'] . ')', $mealComponents['Grasas']['options']);
    }
    
    // Si no hay opciones, usar defaults basados en presupuesto
    if (empty($proteinOptions)) {
        $budget = strtolower($profileData['budget']);
        if (str_contains($budget, 'bajo')) {
            $proteinOptions = ['Huevo entero', 'Pollo muslo', 'Atún en lata', 'Frijoles'];
        } else {
            $proteinOptions = ['Pechuga de pollo', 'Salmón', 'Claras de huevo', 'Yogurt griego'];
        }
    }
    
    if (empty($carbOptions)) {
        $dietStyle = strtolower($profileData['dietary_style']);
        if (str_contains($dietStyle, 'keto')) {
            $carbOptions = ['Vegetales verdes', 'Coliflor', 'Brócoli', 'Espinacas'];
        } else {
            $carbOptions = ['Arroz', 'Quinua', 'Papa', 'Avena', 'Pan integral'];
        }
    }
    
    if (empty($fatOptions)) {
        $budget = strtolower($profileData['budget']);
        if (str_contains($budget, 'bajo')) {
            $fatOptions = ['Aceite vegetal', 'Maní', 'Aguacate pequeño'];
        } else {
            $fatOptions = ['Aceite de oliva extra virgen', 'Almendras', 'Aguacate hass', 'Nueces'];
        }
    }
    
    $proteinString = implode(', ', array_unique($proteinOptions));
    $carbString = implode(', ', array_unique($carbOptions));
    $fatString = implode(', ', array_unique($fatOptions));
    
    // Preparar listas de restricciones
    $dislikedFoodsList = !empty($profileData['disliked_foods']) 
        ? array_map('trim', explode(',', $profileData['disliked_foods']))
        : [];
    
    $allergiesList = !empty($profileData['allergies'])
        ? array_map('trim', explode(',', $profileData['allergies']))
        : [];
    
    // Determinar características especiales según el contexto
    $needsPortable = str_contains(strtolower($profileData['eats_out']), 'casi todos') || 
                     str_contains(strtolower($profileData['eats_out']), 'veces');
    
    $needsQuick = in_array('Preparar la comida', $profileData['diet_difficulties']) ||
                  in_array('No tengo tiempo para cocinar', $profileData['diet_difficulties']);
    
    $needsAlternatives = in_array('Saber qué comer cuando no tengo lo del plan', $profileData['diet_difficulties']);
    
    // Determinar estilo de comunicación
    $communicationTone = '';
    if (str_contains(strtolower($profileData['communication_style']), 'motivadora')) {
        $communicationTone = "Usa un tono MOTIVADOR y ENERGÉTICO: '¡Vamos {$profileData['name']}!', '¡Esta receta te llevará al siguiente nivel!'";
    } elseif (str_contains(strtolower($profileData['communication_style']), 'directa')) {
        $communicationTone = "Usa un tono DIRECTO y CLARO: Sin rodeos, instrucciones precisas, datos concretos.";
    } elseif (str_contains(strtolower($profileData['communication_style']), 'cercana')) {
        $communicationTone = "Usa un tono CERCANO y AMIGABLE: Como un amigo cocinando contigo.";
    }
    
    $prompt = "
    Eres el chef y nutricionista personal de {$profileData['name']} desde hace años. Conoces PERFECTAMENTE todos sus gustos, rutinas y necesidades.
    
    🔴 **RESTRICCIONES ABSOLUTAS - NUNCA VIOLAR:**
    " . (!empty($dislikedFoodsList) ? 
    "- PROHIBIDO usar estos alimentos que NO le gustan: " . implode(', ', $dislikedFoodsList) : 
    "- No hay alimentos que evitar por preferencia") . "
    " . (!empty($allergiesList) ? 
    "- ALERGIAS MORTALES (NUNCA incluir): " . implode(', ', $allergiesList) : 
    "- No hay alergias reportadas") . "
    " . (!empty($profileData['medical_condition']) ? 
    "- Condición médica a considerar: {$profileData['medical_condition']}" : 
    "- No hay condiciones médicas especiales") . "
    
    📊 **PERFIL COMPLETO DE {$profileData['name']}:**
    - Edad: {$profileData['age']} años, Sexo: {$profileData['sex']}
    - Peso: {$profileData['weight']}kg, Altura: {$profileData['height']}cm, BMI: " . round($profileData['bmi'], 1) . "
    - Estado físico: {$profileData['weight_status']}
    - País: {$profileData['country']} (usa ingredientes locales disponibles)
    - Objetivo principal: {$profileData['goal']}
    - Actividad semanal: {$profileData['weekly_activity']}
    - Deportes que practica: " . (!empty($profileData['sports']) ? implode(', ', $profileData['sports']) : 'Ninguno específico') . "
    - Estilo dietético: {$profileData['dietary_style']}
    - Presupuesto: {$profileData['budget']}
    - Come fuera: {$profileData['eats_out']}
    - Estructura de comidas: {$profileData['meal_count']}
    - Hora específica del {$mealName}: " . $this->getMealTiming($mealName, $profileData['meal_times']) . "
    
    🎯 **OBJETIVOS NUTRICIONALES PARA ESTE {$mealName}:**
    - Calorías objetivo: {$profileData['meal_target_calories']} kcal
    - Proteínas objetivo: {$profileData['meal_target_protein']}g
    - Carbohidratos objetivo: {$profileData['meal_target_carbs']}g
    - Grasas objetivo: {$profileData['meal_target_fats']}g
    
    💪 **DIFICULTADES ESPECÍFICAS A RESOLVER:**
    " . (!empty($profileData['diet_difficulties']) ?
    implode("\n", array_map(fn($d) => "- {$d} → Propón solución específica", $profileData['diet_difficulties'])) :
    "- No hay dificultades específicas reportadas") . "
    
    🌟 **MOTIVACIONES A REFORZAR:**
    " . (!empty($profileData['diet_motivations']) ?
    implode("\n", array_map(fn($m) => "- {$m} → Conecta la receta con esta motivación", $profileData['diet_motivations'])) :
    "- Motivación general de salud") . "
    
    🛒 **INGREDIENTES BASE DISPONIBLES PARA {$profileData['name']}:**
    - Proteínas: {$proteinString}
    - Carbohidratos: {$carbString}
    - Grasas: {$fatString}
    
    📋 **REGLAS ESPECIALES DE GENERACIÓN:**
    " . ($needsPortable ? "- INCLUYE al menos 1 receta PORTABLE para llevar al trabajo/comer fuera" : "") . "
    " . ($needsQuick ? "- Las recetas deben ser RÁPIDAS (máximo 20 minutos)" : "") . "
    " . ($needsAlternatives ? "- DA ALTERNATIVAS para cada ingrediente principal" : "") . "
    " . (str_contains(strtolower($profileData['dietary_style']), 'keto') ? 
    "- KETO ESTRICTO: Máximo 5g carbohidratos netos por receta" : "") . "
    " . (str_contains(strtolower($profileData['dietary_style']), 'vegano') ? 
    "- VEGANO: Solo ingredientes de origen vegetal" : "") . "
    " . (str_contains(strtolower($profileData['dietary_style']), 'vegetariano') ? 
    "- VEGETARIANO: Sin carne ni pescado" : "") . "
    
    {$communicationTone}
    
    **ESTRUCTURA JSON OBLIGATORIA:**
    Genera EXACTAMENTE 3 recetas DIFERENTES y CREATIVAS que {$profileData['name']} amaría:
```json
    {
      \"recipes\": [
        {
          \"name\": \"Nombre creativo en español, auténtico de {$profileData['country']}\",
          \"personalizedNote\": \"Nota PERSONAL para {$profileData['name']} explicando por qué esta receta es PERFECTA para él/ella, mencionando su objetivo de '{$profileData['goal']}' y sus motivaciones\",
          \"instructions\": \"Paso 1: [Instrucción clara y específica]\\nPaso 2: [Siguiente paso]\\nPaso 3: [Finalización]\\nTip personal: [Consejo específico para {$profileData['name']}]\",
          \"readyInMinutes\": 20,
          \"servings\": 1,
          \"calories\": {$profileData['meal_target_calories']},
          \"protein\": {$profileData['meal_target_protein']},
          \"carbs\": {$profileData['meal_target_carbs']},
          \"fats\": {$profileData['meal_target_fats']},
          \"extendedIngredients\": [
            {
              \"name\": \"ingrediente principal\",
              \"original\": \"cantidad específica (peso/medida)\",
              \"localName\": \"Nombre local en {$profileData['country']}\",
              \"alternatives\": \"Alternativas si no está disponible\"
            }
          ],
          \"cuisineType\": \"{$profileData['country']}\",
          \"difficultyLevel\": \"Fácil/Intermedio/Avanzado\",
          \"goalAlignment\": \"Explicación específica de cómo esta receta ayuda con: {$profileData['goal']}\",
          \"sportsSupport\": \"Cómo apoya el entrenamiento de: " . implode(', ', $profileData['sports']) . "\",
          \"portableOption\": " . ($needsPortable ? "true" : "false") . ",
          \"quickRecipe\": " . ($needsQuick ? "true" : "false") . ",
          \"dietCompliance\": \"Cumple con dieta {$profileData['dietary_style']}\",
          \"specialTips\": \"Tips para superar: " . implode(', ', array_slice($profileData['diet_difficulties'], 0, 2)) . "\"
        }
      ]
    }

    IMPORTANTE: 
- Las 3 recetas deben ser MUY diferentes entre sí
- NUNCA uses ingredientes de las listas prohibidas
- Los macros deben ser exactos o muy cercanos a los objetivos
- Usa nombres de recetas creativos y apetitosos en español
- Las instrucciones deben ser claras y fáciles de seguir
- Menciona a {$profileData['name']} por su nombre en las notas personalizadas
";

try {
    $response = Http::withToken(env('OPENAI_API_KEY'))
        ->timeout(150)
        ->post('https://api.openai.com/v1/chat/completions', [
            'model' => 'gpt-4o',
            'messages' => [
                ['role' => 'system', 'content' => 'Eres un chef nutricionista experto en personalización extrema de recetas.'],
                ['role' => 'user', 'content' => $prompt]
            ],
            'response_format' => ['type' => 'json_object'],
            'temperature' => 0.6, // Un poco más creativo pero controlado
            'max_tokens' => 4000
        ]);
    
    if ($response->successful()) {
        $data = json_decode($response->json('choices.0.message.content'), true);
        
        if (json_last_error() === JSON_ERROR_NONE && isset($data['recipes']) && is_array($data['recipes'])) {
            $processedRecipes = [];
            
            foreach ($data['recipes'] as $recipeData) {
                // Enriquecer cada receta con metadatos adicionales
                $recipeData['image'] = null; // Se generará después si es necesario
                $recipeData['analyzedInstructions'] = $this->parseInstructionsToSteps($recipeData['instructions'] ?? '');
                $recipeData['personalizedFor'] = $profileData['name'];
                $recipeData['mealType'] = $mealName;
                $recipeData['generatedAt'] = now()->toIso8601String();
                $recipeData['profileGoal'] = $profileData['goal'];
                $recipeData['budgetLevel'] = $profileData['budget'];
                
                // Validar que la receta cumple con las restricciones
                if ($this->validateRecipeIngredients($recipeData, $profileData)) {
                    $processedRecipes[] = $recipeData;
                } else {
                    Log::warning("Receta generada pero rechazada por contener ingredientes prohibidos", [
                        'recipe_name' => $recipeData['name'] ?? 'Sin nombre'
                    ]);
                }
            }
            
            return $processedRecipes;
        }
    }
    
    Log::error("Error al generar recetas personalizadas", [
        'status' => $response->status(),
        'response' => $response->body(),
        'meal' => $mealName,
        'user' => $profileData['name']
    ]);
    
} catch (\Exception $e) {
    Log::error("Excepción al generar recetas", [
        'error' => $e->getMessage(),
        'meal' => $mealName,
        'user' => $profileData['name']
    ]);
}

return null;

}


  private function validateRecipeIngredients(array $recipe, array $profileData): bool
{
    // Preparar listas de restricciones
    $dislikedFoods = !empty($profileData['disliked_foods']) 
        ? array_map(fn($f) => trim(strtolower($f)), explode(',', $profileData['disliked_foods']))
        : [];
    
    $allergies = !empty($profileData['allergies'])
        ? array_map(fn($a) => trim(strtolower($a)), explode(',', $profileData['allergies']))
        : [];
    
    // Validar cada ingrediente
    foreach ($recipe['extendedIngredients'] ?? [] as $ingredient) {
        $ingredientName = strtolower($ingredient['name'] ?? '');
        $localName = strtolower($ingredient['localName'] ?? '');
        
        // Verificar contra alimentos que no le gustan
        foreach ($dislikedFoods as $disliked) {
            if (!empty($disliked) && (
                str_contains($ingredientName, $disliked) || 
                str_contains($localName, $disliked)
            )) {
                Log::warning("Receta contiene alimento no deseado", [
                    'ingredient' => $ingredient['name'],
                    'disliked_food' => $disliked,
                    'recipe' => $recipe['name'] ?? 'Sin nombre'
                ]);
                return false;
            }
        }
        
        // Verificar contra alergias (MÁS CRÍTICO)
        foreach ($allergies as $allergy) {
            if (!empty($allergy) && (
                str_contains($ingredientName, $allergy) || 
                str_contains($localName, $allergy)
            )) {
                Log::error("¡ALERTA CRÍTICA! Receta contiene alérgeno", [
                    'ingredient' => $ingredient['name'],
                    'allergen' => $allergy,
                    'recipe' => $recipe['name'] ?? 'Sin nombre',
                    'user' => $profileData['name']
                ]);
                return false;
            }
        }
    }
    
    // Validación adicional según estilo dietético
    $dietaryStyle = strtolower($profileData['dietary_style'] ?? '');
    
    if (str_contains($dietaryStyle, 'vegano')) {
        $animalProducts = ['huevo', 'leche', 'queso', 'yogurt', 'carne', 'pollo', 'pescado', 'mariscos', 'miel', 'mantequilla'];
        foreach ($recipe['extendedIngredients'] ?? [] as $ingredient) {
            $ingredientName = strtolower($ingredient['name'] ?? '');
            foreach ($animalProducts as $animal) {
                if (str_contains($ingredientName, $animal)) {
                    Log::warning("Receta no es vegana", [
                        'ingredient' => $ingredient['name'],
                        'recipe' => $recipe['name'] ?? 'Sin nombre'
                    ]);
                    return false;
                }
            }
        }
    }
    
    if (str_contains($dietaryStyle, 'vegetariano')) {
        $meats = ['carne', 'pollo', 'pescado', 'mariscos', 'jamón', 'bacon', 'chorizo', 'salchicha'];
        foreach ($recipe['extendedIngredients'] ?? [] as $ingredient) {
            $ingredientName = strtolower($ingredient['name'] ?? '');
            foreach ($meats as $meat) {
                if (str_contains($ingredientName, $meat)) {
                    Log::warning("Receta no es vegetariana", [
                        'ingredient' => $ingredient['name'],
                        'recipe' => $recipe['name'] ?? 'Sin nombre'
                    ]);
                    return false;
                }
            }
        }
    }
    
    return true;
}


private function parseInstructionsToSteps(string $instructions): array
{
    if (empty($instructions)) {
        return [];
    }
    
    $steps = [];
    $lines = explode("\n", $instructions);
    
    foreach ($lines as $index => $line) {
        $line = trim($line);
        if (!empty($line) && !str_starts_with(strtolower($line), 'tip')) {
            // Remover "Paso X:" del inicio si existe
            $line = preg_replace('/^Paso \d+:\s*/i', '', $line);
            
            $steps[] = [
                'number' => $index + 1,
                'step' => $line
            ];
        }
    }
    
    return $steps;
}

    private function getMealTiming($mealName, $mealTimes): string
    {
        $mealLower = strtolower($mealName);
        
        if (str_contains($mealLower, 'desayuno') && isset($mealTimes['breakfast_time'])) {
            return $mealTimes['breakfast_time'];
        } elseif (str_contains($mealLower, 'almuerzo') && isset($mealTimes['lunch_time'])) {
            return $mealTimes['lunch_time'];
        } elseif (str_contains($mealLower, 'cena') && isset($mealTimes['dinner_time'])) {
            return $mealTimes['dinner_time'];
        }
        
        return 'Horario flexible';
    }

  
    

    private function getMealSpecificTips($mealName, array $profileData): array
{
    $tips = [];
    $mealLower = strtolower($mealName);
    
    // Tips basados en el momento del día
    if (str_contains($mealLower, 'desayuno')) {
        $tips[] = "Desayuno diseñado para darte energía sostenida hasta el almuerzo";
        
        if (!empty($profileData['sports']) && in_array('Gym', $profileData['sports'])) {
            $tips[] = "Perfecto como pre-entreno si vas al gym en la mañana";
        }
        
        if (str_contains(strtolower($profileData['goal']), 'bajar grasa')) {
            $tips[] = "Alto en proteína para activar tu metabolismo desde temprano";
        }
    } elseif (str_contains($mealLower, 'almuerzo')) {
        $tips[] = "Tu comida principal del día con el 40% de tus nutrientes";
        
        if (str_contains($profileData['weekly_activity'], 'trabajo activo')) {
            $tips[] = "Energía para mantener tu rendimiento en tu trabajo activo";
        }
    } elseif (str_contains($mealLower, 'cena')) {
        $tips[] = "Cena balanceada para recuperación nocturna óptima";
        
        if (str_contains(strtolower($profileData['goal']), 'aumentar músculo')) {
            $tips[] = "Rica en proteínas de absorción lenta para síntesis muscular nocturna";
        }
    }
    
    // Tips basados en dificultades específicas
    if (in_array('Controlar los antojos', $profileData['diet_difficulties'])) {
        $tips[] = "Rica en fibra y proteína para mantener saciedad y evitar antojos";
    }
    
    if (in_array('Preparar la comida', $profileData['diet_difficulties'])) {
        $tips[] = "Puedes preparar el doble y guardar para mañana";
    }
    
    return $tips;
}

    

    private function userHasActiveSubscription(User $user): bool
    {
        return $user->subscription_status === 'active';
    }

    private function addTrialMessage(array $planData, string $userName): array
    {
        if (isset($planData['nutritionPlan']['meals'])) {
            foreach ($planData['nutritionPlan']['meals'] as $mealName => &$mealData) {
                $mealData['trial_message'] = [
                    'title' => 'Recetas Personalizadas',
                    'message' => "¡Hola {$userName}! Las recetas personalizadas están disponibles con la suscripción completa.",
                    'upgrade_hint' => 'Activa tu suscripción para acceder a recetas paso a paso.'
                ];
            }
        }

        return $planData;
    }
}