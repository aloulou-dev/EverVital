import SwiftUI

struct RecommendationsView: View {
    let recommendations: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.yellow)
                        .padding(.top)
                    
                    Text("Recommendations")
                        .font(.title)
                        .bold()
                    
                    Text(recommendations)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Health Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecommendationsView(recommendations: "• Exercise regularly\n• Eat a balanced diet\n• Get enough sleep")
}

