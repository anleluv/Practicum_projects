/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Шевчук Анета
 * Дата: 14.04.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT COUNT(*) AS total_users,
       SUM(payer) AS paying_users,
       AVG(payer) AS payer_share
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT r.race,
       SUM(u.payer) AS paying_users,
       COUNT(*) AS total_users,
       AVG(u.payer) AS payer_share
FROM fantasy.users AS u
JOIN fantasy.race AS r USING (race_id)
GROUP BY r.race
ORDER BY payer_share DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT COUNT(*) AS count_purchase,
       SUM(amount) AS total_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount,
       AVG(amount) AS avg_amount,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
       STDDEV(amount) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_purchase,
       COUNT(*) AS total_purchase,
       SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END)::real / COUNT(*) AS zero_share
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH filter_events AS (
    SELECT id, item_code
    FROM fantasy.events
    WHERE amount > 0
),
total_stats AS (
    SELECT COUNT(*) AS total_sales,
           COUNT(DISTINCT id) AS total_buyers
    FROM filter_events
)
SELECT i.item_code,
       i.game_items,
       COUNT(*) AS count_sales,
       COUNT(*)::real / (SELECT total_sales FROM total_stats) AS sales_share,
       COUNT(DISTINCT fe.id) AS count_buyers,
       COUNT(DISTINCT fe.id)::real / (SELECT total_buyers FROM total_stats) AS buyers_share
FROM filter_events AS fe
JOIN fantasy.items AS i USING (item_code)
GROUP BY i.item_code, i.game_items
ORDER BY buyers_share DESC, count_sales DESC, i.item_code;

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH total_users AS (
    SELECT race_id,
           COUNT(*) AS total_users
    FROM fantasy.users
    GROUP BY race_id
),
buyers AS (
    SELECT u.race_id,
           COUNT(*) AS count_buyers,
           AVG(u.payer) AS payer_share
    FROM fantasy.users AS u
    WHERE u.id IN (
        SELECT id
        FROM fantasy.events
        WHERE amount > 0
    )
    GROUP BY u.race_id
),
race_activity AS (
    SELECT race_id,
           AVG(purchase_count) AS avg_purchase,
           AVG(avg_amount) AS avg_avg_amount,
           AVG(total_amount) AS avg_total,
           SUM(total_amount) * 1.0 / SUM(purchase_count) AS avg_amount
    FROM (
        SELECT u.race_id,
               u.id,
               COUNT(*) AS purchase_count,
               AVG(e.amount) AS avg_amount,
               SUM(e.amount) AS total_amount
        FROM fantasy.users AS u
        JOIN fantasy.events AS e USING (id)
        WHERE e.amount > 0
        GROUP BY u.race_id, u.id
    ) AS sub
    GROUP BY race_id
)
SELECT r.race,
       t.total_users,
       b.count_buyers,
       b.count_buyers * 1.0 / t.total_users AS buyers_share,
       b.payer_share,
       ra.avg_purchase,
       ra.avg_avg_amount,
       ra.avg_amount,
       ra.avg_total
FROM total_users AS t
JOIN fantasy.race AS r USING (race_id)
LEFT JOIN buyers AS b USING (race_id)
LEFT JOIN race_activity AS ra USING (race_id)
ORDER BY r.race;