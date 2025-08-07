import SwiftUI
import Charts

struct DailySummaryView: View {
    @ObservedObject var viewModel: SummaryViewModel
    let date: Date
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.title2.bold())
                
                if let dailyData = viewModel.weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    // Daily progress
                    VStack {
                        Text("Daily Progress")
                            .font(.headline)
                        
                        ProgressView(value: min(1.0, Double(dailyData.calories) / Double(viewModel.dailyGoal ?? 2000)))
                            .tint(dailyData.calories > (viewModel.dailyGoal ?? 2000) ? .red : .green)
                        
                        HStack {
                            Text("\(dailyData.calories) cal")
                            Spacer()
                            if let goal = viewModel.dailyGoal {
                                Text("\(goal) cal")
                            }
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Meal list
                    Text("Meals")
                        .font(.headline)
                    
                    ForEach(dailyData.meals) { meal in
                        MealCard(meal: meal)
                    }
                } else {
                    Text("No meals recorded for this day")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Daily Summary")
    }
}