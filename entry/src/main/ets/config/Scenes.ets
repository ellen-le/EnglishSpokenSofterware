import { Scene } from '../model/Practice';
export const SCENES: Scene[] = [
  {
    id: 'restaurant-v1', title: '餐厅点餐', subtitle: '把一份订单说清楚',
    userRole: '准备点餐的顾客', partnerRole: '餐厅服务员',
    opening: 'Welcome! What would you like to order?',
    tasks: [
      { id: 'restaurant-food', label: '表达想要的餐品', prompt: 'What would you like to order?',
        reference: "I'd like a chicken sandwich, please.",
        patterns: ['\\b(?:like|want|have|get|order|take)\\b', '\\b(?:sandwich(?:es)?|burgers?|salads?|pizzas?|coffees?|teas?|noodles|rice|soup|water)\\b'] },
      { id: 'restaurant-quantity', label: '说明数量', prompt: 'How many would you like?',
        reference: 'Two sandwiches, please.',
        patterns: ['\\b(?:one|two|three|four|five|a|an|[1-9])\\s+(?:(?:chicken|beef|large|small)\\s+)?(?:sandwich(?:es)?|burgers?|salads?|pizzas?|coffees?|teas?|bowls?|cups?|bottles?)\\b'] },
      { id: 'restaurant-mode', label: '说明堂食或外带', prompt: 'For here or to go?',
        reference: 'To go, please.', patterns: ['\\b(?:for here|to go|takeaway|take away|eat in|dine in)\\b'] },
      { id: 'restaurant-confirm', label: '确认价格或订单', prompt: 'Your total is ten dollars. Can you confirm the order?',
        reference: "That's correct. How much is it in total?",
        patterns: ["\\b(?:how much|total|confirm|that(?:'s| is) (?:correct|right)|order is correct)\\b"] }
    ]
  },
  {
    id: 'airport-v1', title: '机场值机', subtitle: '完成一次出行沟通',
    userRole: '准备乘机的旅客', partnerRole: '值机工作人员',
    opening: 'Good morning! Where are you flying today?',
    tasks: [
      { id: 'airport-destination', label: '说明目的地', prompt: 'Where are you flying today?',
        reference: "I'm flying to London.", patterns: ['\\b(?:flying|going|flight|traveling|travelling)\\b', '\\bto\\s+(?:london|paris|tokyo|shanghai|beijing|new york|boston)\\b'] },
      { id: 'airport-document', label: '出示旅行证件', prompt: 'May I see your passport, please?',
        reference: 'Here is my passport.', patterns: ['\\b(?:here|this|have)\\b', '\\bpassport\\b'] },
      { id: 'airport-baggage', label: '说明托运行李', prompt: 'How many bags are you checking in?',
        reference: 'I have one bag to check in.', patterns: ['\\b(?:one|two|three|no|zero|[0-3])\\b', '\\b(?:bags?|suitcases?|luggage)\\b'] },
      { id: 'airport-gate', label: '询问登机口或登机时间', prompt: 'Do you have a question about boarding?',
        reference: 'What time does boarding start?', patterns: ['\\b(?:what|when|where|which)\\b', '\\b(?:gate|boarding)\\b'] }
    ]
  },
  {
    id: 'campus-v1', title: '校园交流', subtitle: '和新同学约一次见面',
    userRole: '参加英语活动的学生', partnerRole: '新认识的同学',
    opening: "Hi! I'm Alex. What's your name?",
    tasks: [
      { id: 'campus-name', label: '介绍自己', prompt: "What's your name?",
        reference: 'My name is Lin.', patterns: ["\\b(?:my name is|i am|i'm)\\s+[a-z]+\\b"] },
      { id: 'campus-major', label: '介绍学习专业', prompt: 'What do you study?',
        reference: 'I study computer science.', patterns: ['\\b(?:study|major)\\b', '\\b(?:computer science|engineering|english|business|medicine|math|physics|art)\\b'] },
      { id: 'campus-invite', label: '提出一起活动的邀请', prompt: 'Would you like to plan something together?',
        reference: 'Would you like to join the English club?', patterns: ["\\b(?:would you like|let's|shall we|do you want to)\\b", '\\b(?:join|meet|go|study|practice|practise|have)\\b'] },
      { id: 'campus-time', label: '约定见面时间', prompt: 'When shall we meet?',
        reference: "Let's meet at three tomorrow.", patterns: ['\\b(?:at (?:one|two|three|four|five|six|[0-9]{1,2})|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\b'] }
    ]
  }
];
export function sceneById(id: string): Scene {
  const scene = SCENES.find((item: Scene) => item.id === id);
  if (!scene) { throw new Error('找不到场景，请返回场景列表。'); }
  return scene;
}
